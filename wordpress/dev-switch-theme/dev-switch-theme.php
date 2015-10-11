<?php
/*
Plugin Name: Development Theme Switcher
Plugin URI: https://mnt-tech.fr/
Description: Map theme to specific domain name
Version: 0.1
Author: nierdz
Author URI: https://mnt-tech.fr/
License: GPL
*/

//Ajout du support du theme de dev
if ($_SERVER['HTTP_HOST'] === 'dev.tenminutestokill.com') {
	global $static_url;
	global $home_url;
	$static_url = 'http://static.tenminutestokill.com/dev';
	$home_url = 'http://dev.tenminutestokill.com/';
	add_filter( 'pre_option_siteurl', 'siteurl' );
	add_filter( 'pre_option_home', 'home' );
	add_filter( 'template', 'TMTKdev' );
	add_filter( 'stylesheet', 'TMTKdev' );
	add_filter( 'option_template', 'TMTKdev' );
	add_filter( 'option_stylesheet', 'TMTKdev' );
}

function TMTKdev() {
        return 'TMTKdev';
}

function siteurl() {
        return 'http://dev.tenminutestokill.com';
}

function home() {
        return 'http://dev.tenminutestokill.com';
}
?>
