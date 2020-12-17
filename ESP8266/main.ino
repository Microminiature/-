#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>

#define D5 14

ESP8266WebServer server(80);

String str_html =
    "<!DOCTYPE html>"
    "<html lang=\"en\">"
    "<head>"
    "    <meta charset=\"UTF-8\">"
    "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
    "    <title>control</title>"
    "    <script>"
    "        function sendData() {"
    "          led_init_value = eval(\"0x\" + led_value_set.value).toString(10);"
    "          directions = document.getElementsByName(\"direction\");"
    "          direction = directions[0].checked ? 0 : 1;"
    "          speed = sliderValue.textContent;"
    "          var xmlhttp = new XMLHttpRequest();"
    "          xmlhttp.onreadystatechange=function(){"
    "                 if(xmlhttp.readyState==4 && xmlhttp.status==200){"
    "                   xmlDoc=xmlhttp.responseText;"
    "                   alert(xmlDoc);"
    "                 };"
    "          };"
    "          xmlhttp.open(\"GET\", \"initCtrlData?led_init_value=\" + led_init_value + \"&direction=\" + direction + \"&speed=\" + speed, false);"
    "          xmlhttp.send();"
    "      }"
    "  </script>"
    "</head>"
    "<body>"
    "  <div class=\"center\" style=\"font-size: larger;\">"
    "      <br>"
    "      &nbsp;LED状态初值: 0x<input type=\"text\" id=\"led_value_set\" value=\"8\" maxlength=\"2\" required>"
    "      <br><br>"
    "      &nbsp;方向: <label><input name=\"direction\" type=\"radio\" value=\"left\" checked=\"checked\">向左</label>"
    "      <label><input name=\"direction\" type=\"radio\" value=\"right\">向右</label>"
    "      <br><br>"
    "      &nbsp;速度: <span id='slider_value'>05</span>&nbsp;&nbsp;"
    "      慢<input id='slider' type='range' min='0' max='10' step='0' value='5' />快"
    "      <br><br>"
    "      &nbsp;<button type=\"button\" onclick=\"sendData()\">开始</button>"
    "  </div>"
    "</body>"
    "<script>"
    "  var slider = document.getElementById('slider');"
    "  var sliderValue = document.getElementById('slider_value');"
    "  window.onload = function () {"
    "      led_value_set.value = 8;"
    "      slider.value = 5;"
    "      slider.addEventListener('input', function (e) {"
    "          text = e.target.value;"
    "          sliderValue.textContent = text.length > 1 ? text : \"0\" + text;"
    "      });"
    "  }"
    "</script>"
    "</html>";

void SettingAP()
{
  String ssid = "WiFi智能流水灯";
  String password = "12345678";
  IPAddress mylocalIP(192, 168, 5, 2);
  IPAddress gateWay(192, 168, 5, 1);
  IPAddress subNet(255, 255, 255, 0);
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(mylocalIP, gateWay, subNet);
  WiFi.softAP(ssid, password, 1, 0, 10); //信道1，ssid可见，最大10个设备连接
}

/**
 * 初始化浏览器访问默认主页面
 */
void HandleRoot()
{
  server.send(200, "text/html", str_html);
}

/**
 * 处理从网页提交过来的三组数据，并分别以8bit发送
 */
void HandleData()
{
  String led_value = server.arg("led_init_value");
  String direction = server.arg("direction");
  String speed = server.arg("speed");

  byte value = led_value.toInt();
  byte direct = direction.toInt();
  byte velocity = speed.toInt();

  digitalWrite(D5, LOW); //产生一个上升沿，D5用作触发中断
  digitalWrite(D5, HIGH);
  delay(300);
  //  Serial.flush();
  Serial.write(value);
  //delay(200);
  Serial.flush();
  Serial.write(direct);
  //delay(200);
  Serial.flush();
  Serial.write(velocity);
  //delay(200);

  String text = "串口已发送 初值:" + String(value) + " 方向:向" + (direct == 0 ? "左" : "右") + " 速度:" + String(velocity);
  server.send(200, "text/plain", text); //返回服务器串口发送相关数据
}

void setup()
{
  // put your setup code here, to run once:
  Serial.begin(9600, SERIAL_8E1);
  pinMode(D5, OUTPUT);
  digitalWrite(D5, LOW);
  SettingAP();                                      //开启热点
  server.on("/", HandleRoot);                       //主网页
  server.on("/initCtrlData", HTTP_GET, HandleData); //提交数据页面
  server.begin();
}

void loop()
{
  server.handleClient();
}
