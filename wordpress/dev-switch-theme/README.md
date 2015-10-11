# DEV SWITCH THEME

This is a WordPress plugin to switch to another theme when you're browsing your site with a different domain name.  
For example, I use TMTK theme when browsing tenminutestokill.com but TMTKdev theme when browsing dev.tenminutestokill.com.  
This is usefull when you want to use the same vhost and the same database to dev on your site.  

## HOW TO USE THIS PLUGIN
You put this folder in plugins directory and edit to reflect your own setup.  
I used to serve all static content like js, images, etc from a different domain name. If you do the same, you'll need to use :  
`$static_url = 'http://static.tenminutestokill.com/dev';`  
You have to put all your static content in a dev folder and use something like that to include your css and js :  
`global $static_url;  
if (!isset($static_url)) {  
        $static_url = 'http://static.tenminutestokill.com';  
}  
`  
If `$static_url` is set, it means your in dev environment and if it's not the case just set it to your usual static url.  
That way, you can use `$static_url` to include js and css. Here is an example for main.js which needs jquery to be loaded before :  
`wp_register_script( 'main', "$static_url/js/main.js", array('jquery'), $tmtk_version );  
wp_enqueue_script( 'main' );`


