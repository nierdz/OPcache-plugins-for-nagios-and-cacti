<?php
# ============================================================================
# This script is totally inspired from the Percona monitoring plugins.
# https://www.percona.com/doc/percona-monitoring-plugins/1.1/index.html
# 
# This is an adaptation by Kevin MET (https://mnt-tech.fr) to analyse logs
# from web servers (apache, nginx).
# All informations can be found here :
# https://git.mnt-tech.fr/admintools.git/tree/master/cacti/logs
# ===========================================================================

# ============================================================================
# To make this code testable, we need to prevent code from running when it is
# included from the test script.  The test script and this file have different
# filenames, so we can compare them.  In some cases $_SERVER['SCRIPT_FILENAME']
# seems not to be defined, so we skip the check -- this check should certainly
# pass in the test environment.
# ============================================================================
if ( !array_key_exists('SCRIPT_FILENAME', $_SERVER)
   || basename(__FILE__) == basename($_SERVER['SCRIPT_FILENAME']) ) {

# ============================================================================
# CONFIGURATION
# ============================================================================
# Define parameters.  Instead of defining parameters here, you can define them
# in another file named the same as this file, with a .cnf extension in the
# folder /etc/cacti/
# ============================================================================
$ssh_user   = 'root';                                           # SSH username
$ssh_port   = 22;                                                   # SSH port
$ssh_iden   = '-i /etc/cacti/id_rsa';                           # SSH identity
$ssh_tout   = 10;                                        # SSH connect timeout
$cmd_tout   = 10;             # Command exec timeout (ssh itself or local cmd)
$poll_time  = 300;                    # Adjust to match your polling interval.
$timezone   = null;     # If not set, uses the system default.  Example: "UTC"
$debug      = FALSE;             # Define whether you want debugging behavior.
$debug_log  = FALSE;             # If $debug_log is a filename, it'll be used.

# ============================================================================
# You should not need to change anything below this line.
# ============================================================================
$version = '0.2';

# ============================================================================
# Include settings from an external config file in /etc/cacti
# ============================================================================
if ( file_exists('/etc/cacti/' . basename(__FILE__) . '.cnf' ) ) {
   require('/etc/cacti/' . basename(__FILE__) . '.cnf');
   debug('Found configuration file /etc/cacti/' . basename(__FILE__) . '.cnf');
}

# Make this a happy little script even when there are errors.
$no_http_headers = true;
ini_set('implicit_flush', false); # No output, ever.
if ( $debug ) {
   ini_set('display_errors', true);
   ini_set('display_startup_errors', true);
   ini_set('error_reporting', 2147483647);
}
else {
   ini_set('error_reporting', E_ERROR);
}
ob_start(); # Catch all output such as notices of undefined array indexes.
function error_handler($errno, $errstr, $errfile, $errline) {
   print("$errstr at $errfile line $errline\n");
   debug("$errstr at $errfile line $errline");
}

# ============================================================================
# Set the default timezone either to the configured, system timezone, or the
# default set above in the script.
# ============================================================================
if ( function_exists("date_default_timezone_set")
   && function_exists("date_default_timezone_get") ) {
   $tz = ($timezone ? $timezone : @date_default_timezone_get());
   if ( $tz ) {
      @date_default_timezone_set($tz);
   }
}

# ============================================================================
# Make sure we can also be called as a script.
# ============================================================================
if (!isset($called_by_script_server)) {
   debug($_SERVER["argv"]);
   array_shift($_SERVER["argv"]); # Strip off this script's filename
   $options = parse_cmdline($_SERVER["argv"]);
   validate_options($options);
   $result = ss_get_by_ssh($options);
   debug($result);
   if ( !$debug ) {
      # Throw away the buffer, which ought to contain only errors.
      ob_end_clean();
   }
   else {
      ob_end_flush(); # In debugging mode, print out the errors.
   }
   print($result);
}

# ============================================================================
# End "if file was not included" section.
# ============================================================================
}

# ============================================================================
# Extracts the desired bits from a string and returns them.
# ============================================================================
function extract_desired ( $options, $text ) {
   debug($text);
   # Split the result up and extract only the desired parts of it.
   $wanted = explode(',', $options['items']);
   $output = array();
   foreach ( explode(' ', $text) as $item ) {
      if ( in_array(substr($item, 0, 2), $wanted) ) {
         $output[] = $item;
      }
   }
   $result = implode(' ', $output);
   debug($result);
   return $result;
}

# ============================================================================
# Validate that the command-line options are here and correct
# ============================================================================
function validate_options($options) {
   $opts = array('host', 'port', 'items', 'type');
   # Show help
   if ( array_key_exists('help', $options) ) {
      usage('');
   }
   # Required command-line options
   foreach ( array('host', 'items', 'type') as $option ) {
      if ( !isset($options[$option]) || !$options[$option] ) {
         usage("Required option --$option is missing");
      }
   }
   foreach ( $options as $key => $val ) {
      if ( !in_array($key, $opts) ) {
         usage("Unknown option --$key");
      }
   }
}

# ============================================================================
# Print out a brief usage summary
# ============================================================================
function usage($message) {
   $usage = <<<EOF
$message
Usage: php check_logs_by_ssh.php --host <host> --type <type> --items <item,...> [OPTION]

General options:

   --host            Hostname to connect to via SSH
   --type            www or cache
   --items           Comma-separated list of the items whose data you want
   --port            SSH port to connect to
   --help            Show usage

EOF;
   die($usage);
}

# ============================================================================
# Parse command-line arguments, in the format --arg value --arg value, and
# return them as an array ( arg => value )
# ============================================================================
function parse_cmdline( $args ) {
   $options = array();
   while (list($tmp, $p) = each($args)) {
      if (strpos($p, '--') === 0) {
         $param = substr($p, 2);
         $value = null;
         $nextparam = current($args);
         if ($nextparam !== false && strpos($nextparam, '--') !==0) {
            list($tmp, $value) = each($args);
         }
         $options[$param] = $value;
      }
   }
   if ( array_key_exists('host', $options) ) {
      $options['host'] = substr($options['host'], 0, 4) == 'tcp:' ? substr($options['host'], 4) : $options['host'];
   }
   debug($options);
   return $options;
}

# ============================================================================
# This is the main function.  Some parameters are filled in from defaults at the
# top of this file.
# ============================================================================
function ss_get_by_ssh( $options ) {
	global $debug, $poll_time;

	# Build and test the type-specific function names.
	$cmdline_func = "$options[type]_cmdline";
	$parsing_func = "$options[type]_parse";
	$getting_func = "$options[type]_get";
	debug("Functions: '$cmdline_func', '$parsing_func'");
	if ( !function_exists($cmdline_func) ) {
		die("The parsing function '$cmdline_func' does not exist");
	}
	if ( !function_exists($parsing_func) ) {
		die("The parsing function '$parsing_func' does not exist");
	}

	# There might be a custom function that overrides the SSH fetch.
	if ( !isset($options['file']) && function_exists($getting_func) ) {
		debug("$getting_func() is defined, will call it");
		$output = call_user_func($getting_func, $options);
	}
	else {
		# Get the command-line to fetch the data, then fetch and parse the data.
		debug("No getting_func(), will use normal code path");
		$cmd = call_user_func($cmdline_func, $options);
		debug($cmd);
		$output = get_command_result($cmd, $options);
	}
	debug($output);
	$result = call_user_func($parsing_func, $options, $output);

	# Define the variables to output.  I use shortened variable names so maybe
	# it'll all fit in 1024 bytes for Cactid and Spine's benefit.  However, don't
	# use things that have only hex characters, thus begin with 'gg' to avoid a
	# bug in Cacti.  This list must come right after the word
	# MAGIC_VARS_DEFINITIONS.  The Perl script parses it and uses it as a Perl
	# variable.
	$keys = array(
		'WWW_200'	=> 'gg',
		'WWW_206'	=> 'gh',
		'WWW_301'	=> 'gi',
		'WWW_302'	=> 'gj',
		'WWW_304'	=> 'gk',
		'WWW_310'	=> 'gl',
		'WWW_400'	=> 'gm',
		'WWW_401'	=> 'gn',
		'WWW_403'	=> 'go',
		'WWW_404'	=> 'gp',
		'WWW_499'	=> 'gq',
		'WWW_500'	=> 'gr',
		'WWW_503'	=> 'gs',
		'CACHE_B'	=> 'ig',
		'CACHE_E'	=> 'ih',
		'CACHE_H'	=> 'ii',
		'CACHE_M'	=> 'ij',
		'CACHE_R'	=> 'ik',
		'CACHE_S'	=> 'il',
		'CACHE_U'	=> 'im'
	);

	# Prepare and return the output.  The output we have right now is the whole
	# info, and we need that but what we return should be only the desired items.
	$output = array();
	foreach ($keys as $key => $short ) {
		# If the value isn't defined, return -1 which is lower than (most graphs')
		# minimum value of 0, so it'll be regarded as a missing value.
		$val = isset($result[$key]) ? $result[$key] : -1;
		$output[] = "$short:$val";
	}
	$result = implode(' ', $output);
	return extract_desired($options, $result);
}

# ============================================================================
# Simple function to replicate PHP 5 behaviour
# ============================================================================
function microtime_float() {
   list( $usec, $sec ) = explode( " ", microtime() );
   return ( (float) $usec + (float) $sec );
}

# ============================================================================
# Execute the command to get the output and return it.
# ============================================================================
function get_command_result($cmd, $options) {
   global $debug, $ssh_user, $ssh_port, $ssh_iden, $ssh_tout, $cmd_tout;

   # If there is a --file, we just use that.
   if ( isset($options['file']) ) {
      return implode("\n", file($options['file']));
   }

   # Build the SSH command line.
   $port = isset($options['port']) ? $options['port'] : $ssh_port;
   $ssh  = "ssh -q -o \"ConnectTimeout $ssh_tout\" -o \"StrictHostKeyChecking no\" "
         . "$ssh_user@$options[host] -p $port $ssh_iden";
   debug($ssh);
   $final_cmd = "$ssh 'timeout $cmd_tout $cmd'";
   debug($final_cmd);
   $start = microtime_float();

   # Use proc_open and stream_select to handle the command exec timeout.
   $descriptorspec = array(
      0 => array("pipe", "r"),
      1 => array("pipe", "w"),
      2 => array("pipe", "w"),
   );
   $pipes = array();
   $endtime = time() + $cmd_tout;
   $process = proc_open($final_cmd, $descriptorspec, $pipes);
   $result = "";
   if (is_resource($process)) {
      do {
         $read = array($pipes[1]);
         $write  = NULL;
         $exeptions = NULL;
         stream_select($read, $write, $exeptions, 1, NULL);
         if (!empty($read)) {
            $result .= fread($pipes[1], 8192);
         }
         $timeleft = $endtime - time();
      } while (!feof($pipes[1]) && $timeleft > 0);
      if ($timeleft <= 0) {
         $result = "timed out";
         proc_terminate($process);
      }
   } else {
      $result = "proc_open failed";
   }

   $end = microtime_float();
   debug(array("Time taken to exec: ", $end - $start));
   debug(array("result of $final_cmd", $result));
   return $result;
}

# ============================================================================
# Writes to a debugging log.
# ============================================================================
function debug($val) {
   global $debug_log;
   if ( !$debug_log ) {
      return;
   }
   if ( $fp = fopen($debug_log, 'a+') ) {
      $trace = debug_backtrace();
      $calls = array();
      $i    = 0;
      $line = 0;
      $file = '';
      foreach ( debug_backtrace() as $arr ) {
         if ( $i++ ) {
            $calls[] = "$arr[function]() at $file:$line";
         }
         $line = array_key_exists('line', $arr) ? $arr['line'] : '?';
         $file = array_key_exists('file', $arr) ? $arr['file'] : '?';
      }
      if ( !count($calls) ) {
         $calls[] = "at $file:$line";
      }
      fwrite($fp, date('Y-m-d H:i:s') . ' ' . implode(' <- ', $calls));
      fwrite($fp, "\n" . var_export($val, TRUE) . "\n");
      fclose($fp);
   }
   else { # Disable logging
      print("Warning: disabling debug logging to $debug_log\n");
      $debug_log = FALSE;
   }
}

# ============================================================================
# Everything from this point down is the functions that do the specific work to
# get and parse command output.  These are called from get_by_ssh().  The work
# is broken down into parts by several functions, one set for each type of data
# collection, based on the --type option:
# 1) Build a command-line string.
#    This is done in $type_cmdline() and will often be trivially simple.  The
#    resulting command-line string should use double-quotes wherever quotes
#    are needed, because it'll end up being enclosed in single-quotes if it
#    is executed remotely via SSH (which is typically the case).
# 2) SSH to the server and execute that command to get its output.
#    This is common code called from get_by_ssh(), in get_command_result().
# 3) Parse the result.
#    This is done in $type_parse().
# ============================================================================

# ============================================================================
# Gets and parses apache or nginx log file.
# Options used: none.
# You can test it like this, as root:
# su -l www-data -s /bin/bash -c "php /usr/share/cacti/site/scripts/check_logs_by_ssh.php --host 192.168.1.100 --type www --items gg,gh,gi,gj,gk,gl,gm,gn,go,gp,gq"
# ============================================================================
function www_cmdline ( $options ) {
   global $logs_www_cmd;
   return "$logs_www_cmd";
}

function www_parse ( $options, $output ) {
	$result = array(
		'WWW_200'	=> null,
		'WWW_206'	=> null,
		'WWW_301'	=> null,
		'WWW_302'	=> null,
		'WWW_304'	=> null,
		'WWW_310'	=> null,
		'WWW_400'	=> null,
		'WWW_401'	=> null,
		'WWW_403'	=> null,
		'WWW_404'	=> null,
		'WWW_499'	=> null,
		'WWW_500'	=> null,
		'WWW_503'	=> null
	);

   foreach ( explode("\n", $output) as $line ) {
      if ( preg_match_all('/\w+/', $line, $words) ) {
        $words = $words[0];
         if ( $words[0] == "200" ) {
            $result['WWW_200'] = $words[1];
         }
         if ( $words[0] == "206" ) {
            $result['WWW_206'] = $words[1];
         }
         elseif ( $words[0] == "301" ) {
            $result['WWW_301'] = $words[1];
         }
         elseif ( $words[0] == "302" ) {
            $result['WWW_302'] = $words[1];
         }
         elseif ( $words[0] == "304" ) {
            $result['WWW_304'] = $words[1];
         }
         elseif ( $words[0] == "310" ) {
            $result['WWW_310'] = $words[1];
         }
         elseif ( $words[0] == "400" ) {
            $result['WWW_400'] = $words[1];
         }
         elseif ( $words[0] == "401" ) {
            $result['WWW_401'] = $words[1];
         }
         elseif ( $words[0] == "403" ) {
            $result['WWW_403'] = $words[1];
         }
         elseif ( $words[0] == "404" ) {
            $result['WWW_404'] = $words[1];
         }
         elseif ( $words[0] == "499" ) {
            $result['WWW_499'] = $words[1];
         }
         elseif ( $words[0] == "500" ) {
            $result['WWW_500'] = $words[1];
         }
         elseif ( $words[0] == "503" ) {
            $result['WWW_503'] = $words[1];
         }
      }
   }
   return $result;
}

# ============================================================================
# Gets and parses cache log files from nginx.
# To get this log use this : https://rtcamp.com/tutorials/nginx/upstream-cache-status-in-access-log/
# You can test it like this, as root:
# su -l www-data -s /bin/bash -c "php /usr/share/cacti/site/scripts/check_logs_by_ssh.php --host 192.168.1.100 --type cache --items ig,ih,ii,ij,ik,il,im"
# ============================================================================


function cache_cmdline ( $options ) {
	global $logs_cache_cmd;
	return "$logs_cache_cmd";
}

function cache_parse ( $options, $output ) {
	$result = array(
		'CACHE_B'	=> null,
		'CACHE_E'	=> null,
		'CACHE_H'	=> null,
		'CACHE_M'	=> null,
		'CACHE_R'	=> null,
		'CACHE_S'	=> null,
		'CACHE_U'	=> null
	);

	foreach ( explode("\n", $output) as $line ) {
		if ( preg_match_all('/\w+/', $line, $words) ) {
			$words = $words[0];
			if ( $words[0] == "BYPASS" ) {
				$result['CACHE_B'] = $words[1];
			}
			elseif ( $words[0] == "EXPIRED" ) {
				$result['CACHE_E'] = $words[1];
			}
			elseif ( $words[0] == "HIT" ) {
				$result['CACHE_H'] = $words[1];
			}
			elseif ( $words[0] == "MISS" ) {
				$result['CACHE_M'] = $words[1];
			}
			elseif ( $words[0] == "REVALIDATED" ) {
				$result['CACHE_R'] = $words[1];
			}
			elseif ( $words[0] == "STALE" ) {
				$result['CACHE_S'] = $words[1];
			}
			elseif ( $words[0] == "UPDATING" ) {
				$result['CACHE_U'] = $words[1];
			}
		}
	}
	return $result;
}

