#!/usr/bin/env node

"use strict";

const pg = require("pg");
const app = require('express')()
const bodyParser = require('body-parser');
const qr_prefix = "https://chart.googleapis.com/chart?cht=qr&chs=540x540&chl=";

const costs = {
    "20": 2.80,
    "40": 3.80,
    "60": 5,
    "90": 6
};

const one_journey_ticket = "40";

pg.types.setTypeParser(1114, function(stringValue) {
    return new Date(Date.parse(stringValue + "+0000"));
});


function getCost(time, switched_vehicle) {
    if(switched_vehicle == undefined) {
        switched_vehicle = false;
    }

    if(switched_vehicle || time < parseInt(one_journey_ticket)) {
        let types = Object.keys(costs).map((v) => parseInt(v));
        types.sort();
        types.reverse();

        let i = 0;
        let cost = 0;
        let ticket_time = 0;
        while(time > 0) {
            while(i+1 < types.length && time < types[i+1]) {
                i += 1;
            }
            time -= types[i];
            ticket_time += types[i];
            cost += costs[types[i].toString()];
        }

        return { cost, time: ticket_time,
            one_journey_ticket: false
        };
    } else {
        return {
            cost: costs[one_journey_ticket],
            time: parseInt(one_journey_ticket),
            one_journey_ticket: true
        }
    }

}

let client = null;

app.use(bodyParser.urlencoded({extended:false}));

app.use((req, res, next) => {
    res.type("json");
    next();
});

app.use((req, res, next) => {
    if(!req.body.device_id) {
        res.send({"status": "client_error", "message": "Missing device_id"});
    } else {
        next();
    }
});

app.post('/buy_ticket', (req, res) => {
    console.log('buy ticket', req.body);
    let did = req.body.device_id;

    client.query(`INSERT INTO journeys (device_id) VALUES ($1) RETURNING started`, [did], (err, result) => {
        if(err) throw err;

        let started = new Date(result.rows[0].started);
        let cost = getCost(0.01);
        let time = cost.time;
        let one_journey_ticket = cost.one_journey_ticket;
        cost = cost.cost;

        let expires = new Date(started.getTime() + time*60*1000);
        let refresh_in = (expires - new Date()) - 1000;

        res.send({
            status: "new_ticket",
            cost: cost,
            qr_code: `${qr_prefix}${expires.toISOString()};signature`,
            started: started.toISOString(),
            one_journey_ticket,
            expires: expires.toISOString(),
            refresh_in: parseInt(refresh_in/1000/60)
        });
    });
});

app.post('/refresh', (req, res) => {
    console.log('refresh', req.body);
    if(req.body.in_region == undefined) {
        res.send({"status": "client_error", "message": "Missing in_region"});
        return;
    }

    if(req.body.switched_vehicle == undefined) {
        res.send({"status": "client_error", "meesage": "Missing switched_vehicle"});
        return;
    }

    let did = req.body.device_id;
    let switched_vehicle = req.body.switched_vehicle == '1';

    if(req.body.in_region === "1") {
        client.query("SELECT started FROM journeys WHERE device_id = $1 AND finished is NULL ORDER BY started DESC LIMIT 1", [did], (err, result) => {
            let started = new Date(result.rows[0].started);
            let time = new Date() - started + 60*1000
            let cost = getCost(time / 1000 / 60, switched_vehicle);
            let one_journey_ticket = cost.one_journey_ticket;
            time = cost.time;
            cost = cost.cost;

            let expires = new Date(started.getTime() + time*60*1000);
            let refresh_in = (expires - new Date()) - 1000;

            res.send({
                status: "ticket_extended",
                cost: cost,
                qr_code: `${qr_prefix}${expires.toISOString()};signature`,
                started: started.toISOString(),
                expires: expires.toISOString(),
                one_journey_ticket,
                refresh_in: parseInt(refresh_in/1000/60)
            });
        });
    } else {
        client.query("SELECT id, started FROM journeys WHERE device_id = $1 AND finished is NULL ORDER BY started DESC limit 1", [did], (err, result) => {
            client.query("UPDATE journeys SET finished = CURRENT_TIMESTAMP at time zone 'UTC' WHERE id = $1", [result.rows[0].id]);
            let started = new Date(result.rows[0].started);
            let time = new Date() - started;
            let cost = getCost(time / 1000 / 60, switched_vehicle);
            let one_journey_ticket = cost.one_journey_ticket;
            time = cost.time;
            cost = cost.cost;

            let expires = new Date(started.getTime() + time*60*1000);
            let refresh_in = (expires - new Date()) - 1000;
            let finished = new Date();

            res.send({
                status: "finished",
                cost: cost,
                started: started.toISOString(),
                one_journey_ticket,
                finished: finished.toISOString(),
                duration: (finished - started)/60/1000
            });
        });
    }
});

pg.connect("postgres://bv2015@localhost/bv2015", (err, c, done) => {
    if(err) throw err;
    c.query("set time zone 'UTC'");
    client = c;

    app.listen(3000, '0.0.0.0');
});
