package eu.kazimierowicz.ticketcontrol;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;


public class MainActivity extends ActionBarActivity {
    Button scanButton;
    TextView tv;
    TextView tv2;
    ImageView clr;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        //scanButton = (Button) findViewById(R.id.scan_button);
        clr = (ImageView) findViewById(R.id.clr);
        tv = (TextView) findViewById(R.id.tv);
        tv2 = (TextView) findViewById(R.id.tv2);

        clr.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                   scan();
            }
        });
        scan();
    }

    @Override
    protected void onResume() {
        super.onResume();
      //  try{ Thread.sleep(1000); }catch(InterruptedException e){ }
       // scan();
    }

    public void scan(){
        Intent intent = new Intent("com.google.zxing.client.android.SCAN");
        intent.putExtra("SCAN_MODE", "QR_CODE_MODE");
        startActivityForResult(intent, 0);
    }
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (requestCode == 0) {
            if (resultCode == RESULT_OK) {

                String contents = intent.getStringExtra("SCAN_RESULT");
                String format = intent.getStringExtra("SCAN_RESULT_FORMAT");
                Log.i("BLEB", contents);
                String[] str = contents.split(";");

                String dateStr = "yyyy-MM-dd'T'HH:mm:ss.SSS";
                SimpleDateFormat dateFormat = new SimpleDateFormat(dateStr);
                Date now = new Date();

                try {
                    Date date = dateFormat.parse(str[0]);
                    Calendar calendar = Calendar.getInstance();
                    calendar.setTime(date);
                    calendar.add(Calendar.HOUR, 1);
                    date = calendar.getTime();
                    if(now.compareTo(date) < 0){
                        clr.setBackgroundColor(Color.GREEN);
                        tv.setText("Ticket Valid");
                        tv2.setText("Valid for: "+String.valueOf(date.getMinutes()-now.getMinutes())+" minutes.");

                    }else{
                        clr.setBackgroundColor(Color.RED);
                        tv.setText("Ticket Invalid");
                        tv2.setText("Expired: " + String.valueOf(now.getMinutes()-date.getMinutes())+" minutes ago.");
                    }
                    Log.i("BLEB", " :: " +date.toString());
                    Log.i("BLEB", " :# " + now.toString());

                } catch (ParseException e) {
                    e.printStackTrace();
                }


            } else if (resultCode == RESULT_CANCELED) {
                // Handle cancel
                Log.i("App", "Scan unsuccessful");
            }
        }
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
