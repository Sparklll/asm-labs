#include <termios.h>

static struct termios old, current;

void init_termios(int echo) 
{
  tcgetattr(0, &old);
  current = old;
  current.c_lflag &= ~ICANON; /* disable buffered i/o */
  if (echo) {
      current.c_lflag |= ECHO; /* set echo mode */
  } else {
      current.c_lflag &= ~ECHO; /* set no echo mode */
  }
  tcsetattr(0, TCSANOW, &current);
}

void reset_termios() 
{
  tcsetattr(0, TCSANOW, &old);
}
