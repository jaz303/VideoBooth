// simple sketch for interfacing with a bunch of illuminated buttons over the serial port
//
// buttons can be enabled or disabled. LEDs of enabled buttons will be illuminated,
// and disabled buttons do not relay press events over the serial connection.
// buttons are addressed by letter: a, b, c etc.
// when an enabled button is pressed, its uppercase ASCII representation (e.g. 'A', or 0x41)
// is transmitted over the serial line. button enabled state can be toggled by sending ASCII
// to the board - uppercase to enable, lowercase to disable.

typedef struct {
  int led_pin;
  int button_pin;
  int enabled;
  int state;
} button_t;

#define NUM_BUTTONS 2
button_t buttons[NUM_BUTTONS] = {
  { 3, 2, 0, LOW},
  { 5, 4, 0, LOW }
};

void enableButton(int ix) {
  digitalWrite(buttons[ix].led_pin, HIGH);
  buttons[ix].enabled = 1;
}

void disableButton(int ix) {
  digitalWrite(buttons[ix].led_pin, LOW);
  buttons[ix].enabled = 0;
}

void setup()
{
  int i;
  for (i = 0; i < NUM_BUTTONS; i++) {
    pinMode(buttons[i].led_pin, OUTPUT);
    pinMode(buttons[i].button_pin, INPUT);
    digitalWrite(buttons[i].button_pin, HIGH);
		if (buttons[i].enabled) {
			enableButton(i);
		} else {
			disableButton(i);
		}
  }
  
  Serial.begin(9600);
}

void loop() 
{
  if (Serial.available() > 0) {
    byte v = Serial.read();
    if (v >= 65) {
      v -= 65;
      int on = 1;
      if (v >= 32) {
        on = 0;
        v -= 32;
      }
      if (v < NUM_BUTTONS) {
        if (on) {
          enableButton(v);
        } else {
          disableButton(v);
        }
      }
    }
  }
  
  int i;
  for (i = 0; i < NUM_BUTTONS; i++) {
    if (!buttons[i].enabled) continue;
    int state = digitalRead(buttons[i].button_pin);
    if (state == LOW && buttons[i].state == HIGH) {
      Serial.write(65 + i);
    }
    buttons[i].state = state;
  }
  
}
