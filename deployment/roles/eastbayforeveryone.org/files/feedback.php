<?php
/*
 * Plugin Name: East Bay for Everyone
 * Description: Custom behavior to support our migration off of wordpress.com.
 * Plugin URI: https://github.com/kevinburke/eastbayforeveryone.org
 * License: MIT
 */
/*
 * We need this because we previously used Jetpack, which creates a bunch of
 * posts with the "feedback" type. We don't want to enable Jetpack on our site.
 * https://wordpress.stackexchange.com/a/252078/16825
 */
add_action( 'init', function () {
    register_post_type( 'feedback', [
        'public' => true,
        'labels' => [
            'singular_name' => 'Feedback',
            'name'          => 'Feedback',
        ]
    ]);
});

// Code taken from the "enable-svg-uploads" plugin, which is GPL 3.0 licensed,
// with modifications.
//
// https://wordpress.org/plugins/enable-svg-uploads/
function fix_mime_type_svg(
    $data = null, $file = null, $filename = null, $mimes = null
) {
    $original_extension = ( isset( $data['ext'] ) ? $data['ext'] : '' );
    if ($original_extension === '' || is_null($original_extension)) {
        $ext = pathinfo($filename, PATHINFO_EXTENSION);
    } else {
        $ext = $original_extension;
    }
    if ( $ext === 'svg' ) {
        $data['type'] = 'image/svg+xml';
        $data['ext']  = 'svg';
    }
    return $data;
}
add_filter( 'wp_check_filetype_and_ext', 'fix_mime_type_svg', 75, 4 );

// Wordpress does not allow SVG upload by default but our image is SVG
function allow_svg_upload($mimes) {
    $mimes['svg'] = 'image/svg+xml';
    return $mimes;
}
add_filter('upload_mimes', 'allow_svg_upload');
