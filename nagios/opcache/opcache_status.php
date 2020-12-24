<?php
header('Content-Type: text/plain');
$opcachestat = opcache_get_status( );
$opcacheconfig = opcache_get_configuration( );
print $opcachestat['memory_usage']['used_memory']."\n";
print $opcachestat['memory_usage']['free_memory']."\n";
print $opcachestat['memory_usage']['wasted_memory']."\n";
print $opcachestat['opcache_statistics']['num_cached_scripts']."\n";
print $opcachestat['opcache_statistics']['num_cached_keys']."\n";
print $opcachestat['opcache_statistics']['max_cached_keys']."\n";
print $opcachestat['opcache_statistics']['hits']."\n";
print $opcachestat['opcache_statistics']['misses']."\n";
print $opcachestat['interned_strings_usage']['used_memory']."\n";
print $opcachestat['interned_strings_usage']['free_memory']."\n";
print $opcachestat['interned_strings_usage']['buffer_size']."\n";
print $opcachestat['opcache_statistics']['oom_restarts']."\n";
print $opcachestat['opcache_statistics']['hash_restarts']."\n";
print $opcacheconfig['directives']['opcache.memory_consumption']."\n";
print $opcacheconfig['directives']['opcache.enable']."\n";
print $opcacheconfig['version']['opcache_product_name'].'-'.$opcacheconfig['version']['version']."\n";
?>
