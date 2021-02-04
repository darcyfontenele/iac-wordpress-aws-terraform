<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', '${db_name}' );

/** MySQL database username */
define( 'DB_USER', '${db_user}' );

/** MySQL database password */
define( 'DB_PASSWORD', '${db_pass}' );

/** MySQL hostname */
define( 'DB_HOST', '${db_host}:${db_port}' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'u>;&40OHu#(0w`X5=O:n4SLz|.~Qr#9P:CW&iUTm:a:f_.#~)i|AGy l11tn)z50');
define('SECURE_AUTH_KEY',  'NG#e^&J$BfEqZH{n{0|?z(>F(V*7kV}pL27r(ERV|hSb.4-*}T`8(|bV[UOT4YD]');
define('LOGGED_IN_KEY',    '`Apu@M?Br/|%1+j2O|arKhn5Mg`uj^~ra?7@[1_FVQq-^-[1v<[3jdDP/,@|j1uX');
define('NONCE_KEY',        'o9&xtII=rienwo2|Zb^W;{f(-MVYhwO]Q3-kIx5gwEPl=2LEEUnpJ.G0s|S-N+}V');
define('AUTH_SALT',        'k9ygnP&UO&<%K+m+Y(vcTg;+OiD^Bzo Ky3:Lxh650TA)SZ2VK/<^V4?FRl$!-Q0');
define('SECURE_AUTH_SALT', '-P@rmH%_SfRy;M4QJj1=D_R kw$loNsx>s:)+ylOm ?t%W<bX>EsZNKp,C]|jve1');
define('LOGGED_IN_SALT',   'O[WUaH9cJ: <4CySb_Cqj7Y{^R(<|-G~L a*HfLcoto2_+M?*Z(F5d$MMg=,fKpv');
define('NONCE_SALT',       '|>Rt`YdC2[X)QSiFa}+]h/M+k[%6IL3_X;@GBZ1)tH+DZP>=X4H*y~X<(>zT7A|/');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );