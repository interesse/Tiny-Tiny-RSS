drop table ttrss_linked_feeds;
drop table ttrss_linked_instances;
drop table ttrss_access_keys;
drop table ttrss_user_labels2;
drop table ttrss_labels2;
drop table ttrss_feedbrowser_cache;
drop table ttrss_version;
drop table ttrss_labels;
drop table ttrss_filters;
drop table ttrss_filter_types;
drop table ttrss_filter_actions;
drop table ttrss_user_prefs;
drop table ttrss_prefs;
drop table ttrss_prefs_types;
drop table ttrss_prefs_sections;
drop table ttrss_tags;
drop table ttrss_enclosures;
drop table ttrss_settings_profiles;
drop table ttrss_entry_comments;
drop table ttrss_user_entries;
drop table ttrss_entries;
drop table ttrss_scheduled_updates;
drop table ttrss_counters_cache;
drop table ttrss_cat_counters_cache;
drop table ttrss_archived_feeds;
drop table ttrss_feeds;
drop table ttrss_feed_categories;
drop table ttrss_users;
drop table ttrss_themes;
drop table ttrss_sessions;
drop function SUBSTRING_FOR_DATE(timestamp, int, int);

begin;

create table ttrss_users (id serial not null primary key,
	login varchar(120) not null unique,
	pwd_hash varchar(250) not null,
	last_login timestamp default null,
	access_level integer not null default 0,
	email varchar(250) not null default '',
	full_name varchar(250) not null default '',
	email_digest boolean not null default false,
	last_digest_sent timestamp default null,
	twitter_oauth text default null,
	created timestamp default null);

insert into ttrss_users (login,pwd_hash,access_level) values ('admin',
	'SHA1:5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8', 10);

create table ttrss_feed_categories(id serial not null primary key,
	owner_uid integer not null references ttrss_users(id) on delete cascade,
	collapsed boolean not null default false,
	order_id integer not null default 0,
	title varchar(200) not null);

create table ttrss_feeds (id serial not null primary key,
	owner_uid integer not null references ttrss_users(id) on delete cascade,
	title varchar(200) not null,
	cat_id integer default null references ttrss_feed_categories(id) on delete set null,
	feed_url text not null,
	icon_url varchar(250) not null default '',
	update_interval integer not null default 0,
	purge_interval integer not null default 0,
	last_updated timestamp default null,
	last_error text not null default '',
	site_url varchar(250) not null default '',
	auth_login varchar(250) not null default '',
	parent_feed integer default null references ttrss_feeds(id) on delete set null,
	private boolean not null default false,
	auth_pass varchar(250) not null default '',
	hidden boolean not null default false,
	include_in_digest boolean not null default true,
	rtl_content boolean not null default false,
	cache_images boolean not null default false,
	last_viewed timestamp default null,
	last_update_started timestamp default null,
	update_method integer not null default 0,
	always_display_enclosures boolean not null default false,
	order_id integer not null default 0,
	mark_unread_on_update boolean not null default false,
	update_on_checksum_change boolean not null default false,
	strip_images boolean not null default false,
	pubsub_state integer not null default 0,
	auth_pass_encrypted boolean not null default false);

create index ttrss_feeds_owner_uid_index on ttrss_feeds(owner_uid);

insert into ttrss_feeds (owner_uid, title, feed_url) values
	(1, 'Tiny Tiny RSS: New Releases', 'http://tt-rss.org/releases.rss');

insert into ttrss_feeds (owner_uid, title, feed_url) values
	(1, 'Tiny Tiny RSS: Forum', 'http://tt-rss.org/forum/rss.php');

create table ttrss_archived_feeds (id integer not null primary key,
	owner_uid integer not null references ttrss_users(id) on delete cascade,
	title varchar(200) not null,
	feed_url text not null,
	site_url varchar(250) not null default '');

create table ttrss_counters_cache (
	feed_id integer not null,
	owner_uid integer not null references ttrss_users(id) ON DELETE CASCADE,
	updated timestamp not null,
	value integer not null default 0);

create index ttrss_counters_cache_feed_id_idx on ttrss_counters_cache(feed_id);
create index ttrss_counters_cache_owner_uid_idx on ttrss_counters_cache(owner_uid);
create index ttrss_counters_cache_value_idx on ttrss_counters_cache(value);

create table ttrss_cat_counters_cache (
	feed_id integer not null,
	owner_uid integer not null references ttrss_users(id) ON DELETE CASCADE,
	updated timestamp not null,
	value integer not null default 0);

create index ttrss_cat_counters_cache_owner_uid_idx on ttrss_cat_counters_cache(owner_uid);

create table ttrss_entries (id serial not null primary key,
	title text not null,
	guid text not null unique,
	link text not null,
	updated timestamp not null,
	content text not null,
	content_hash varchar(250) not null,
	no_orig_date boolean not null default false,
	date_entered timestamp not null,
	date_updated timestamp not null,
	num_comments integer not null default 0,
	comments varchar(250) not null default '',
	author varchar(250) not null default '');

create index ttrss_entries_guid_index on ttrss_entries(guid);
-- create index ttrss_entries_title_index on ttrss_entries(title);
create index ttrss_entries_date_entered_index on ttrss_entries(date_entered);
create index ttrss_entries_updated_idx on ttrss_entries(updated);

create table ttrss_user_entries (
	int_id serial not null primary key,
	ref_id integer not null references ttrss_entries(id) ON DELETE CASCADE,
	feed_id int references ttrss_feeds(id) ON DELETE CASCADE,
	orig_feed_id integer references ttrss_archived_feeds(id) ON DELETE SET NULL,
	owner_uid integer not null references ttrss_users(id) ON DELETE CASCADE,
	marked boolean not null default false,
	published boolean not null default false,
	tag_cache text not null,
	label_cache text not null,
	last_read timestamp,
	score int not null default 0,
	note text,
	unread boolean not null default true);

-- create index ttrss_user_entries_feed_id_index on ttrss_user_entries(feed_id);
create index ttrss_user_entries_owner_uid_index on ttrss_user_entries(owner_uid);
create index ttrss_user_entries_ref_id_index on ttrss_user_entries(ref_id);
create index ttrss_user_entries_feed_id on ttrss_user_entries(feed_id);
create index ttrss_user_entries_unread_idx on ttrss_user_entries(unread);

create table ttrss_entry_comments (id serial not null primary key,
	ref_id integer not null references ttrss_entries(id) ON DELETE CASCADE,
	owner_uid integer not null references ttrss_users(id) ON DELETE CASCADE,
	private boolean not null default false,
	date_entered timestamp not null);

create index ttrss_entry_comments_ref_id_index on ttrss_entry_comments(ref_id);
-- create index ttrss_entry_comments_owner_uid_index on ttrss_entry_comments(owner_uid);

create table ttrss_filter_types (id integer not null primary key,
	name varchar(120) unique not null,
	description varchar(250) not null unique);

insert into ttrss_filter_types (id,name,description) values (1, 'title', 'Title');
insert into ttrss_filter_types (id,name,description) values (2, 'content', 'Content');
insert into ttrss_filter_types (id,name,description) values (3, 'both',
	'Title or Content');
insert into ttrss_filter_types (id,name,description) values (4, 'link',
	'Link');
insert into ttrss_filter_types (id,name,description) values (5, 'date',
	'Article Date');
insert into ttrss_filter_types (id,name,description) values (6, 'author', 'Author');
insert into ttrss_filter_types (id,name,description) values (7, 'tag', 'Article Tags');

create table ttrss_filter_actions (id integer not null primary key,
	name varchar(120) unique not null,
	description varchar(250) not null unique);

insert into ttrss_filter_actions (id,name,description) values (1, 'filter',
	'Delete article');

insert into ttrss_filter_actions (id,name,description) values (2, 'catchup',
	'Mark as read');

insert into ttrss_filter_actions (id,name,description) values (3, 'mark',
	'Set starred');

insert into ttrss_filter_actions (id,name,description) values (4, 'tag',
	'Assign tags');

insert into ttrss_filter_actions (id,name,description) values (5, 'publish',
	'Publish article');

insert into ttrss_filter_actions (id,name,description) values (6, 'score',
	'Modify score');

insert into ttrss_filter_actions (id,name,description) values (7, 'label',
	'Assign label');

create table ttrss_filters (id serial not null primary key,
	owner_uid integer not null references ttrss_users(id) on delete cascade,
	feed_id integer references ttrss_feeds(id) on delete cascade default null,
	filter_type integer not null references ttrss_filter_types(id),
	reg_exp varchar(250) not null,
	filter_param varchar(250) not null default '',
	enabled boolean not null default true,
	inverse boolean not null default false,
	action_id integer not null default 1 references ttrss_filter_actions(id) on delete cascade,
	action_param varchar(250) not null default '');

create table ttrss_tags (id serial not null primary key,
	tag_name varchar(250) not null,
	owner_uid integer not null references ttrss_users(id) on delete cascade,
	post_int_id integer references ttrss_user_entries(int_id) ON DELETE CASCADE not null);

create index ttrss_tags_owner_uid_index on ttrss_tags(owner_uid);
create index ttrss_tags_post_int_id_idx on ttrss_tags(post_int_id);

create table ttrss_version (schema_version int not null);

insert into ttrss_version values (85);

create table ttrss_enclosures (id serial not null primary key,
	content_url text not null,
	content_type varchar(250) not null,
	title text not null,
	duration text not null,
	post_id integer references ttrss_entries(id) ON DELETE cascade NOT NULL);

create table ttrss_settings_profiles(id serial not null primary key,
	title varchar(250) not null,
	owner_uid integer not null references ttrss_users(id) on delete cascade);

create table ttrss_prefs_types (id integer not null primary key,
	type_name varchar(100) not null);

insert into ttrss_prefs_types (id, type_name) values (1, 'bool');
insert into ttrss_prefs_types (id, type_name) values (2, 'string');
insert into ttrss_prefs_types (id, type_name) values (3, 'integer');

create table ttrss_prefs_sections (id integer not null primary key,
	section_name varchar(100) not null);

insert into ttrss_prefs_sections (id, section_name) values (1, 'General');
insert into ttrss_prefs_sections (id, section_name) values (2, 'Interface');
insert into ttrss_prefs_sections (id, section_name) values (3, 'Advanced');

create table ttrss_prefs (pref_name varchar(250) not null primary key,
	type_id integer not null references ttrss_prefs_types(id),
	section_id integer not null references ttrss_prefs_sections(id) default 1,
	short_desc text not null,
	help_text text not null default '',
	access_level integer not null default 0,
	def_value text not null);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('PURGE_OLD_DAYS', 3, '60', 'Purge old posts after this number of days (0 - disables)',1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('DEFAULT_UPDATE_INTERVAL', 3, '30', 'Default interval between feed updates',1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('DEFAULT_ARTICLE_LIMIT', 3, '30', 'Amount of articles to display at once',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('ALLOW_DUPLICATE_POSTS', 1, 'true', 'Allow duplicate posts',1, 'This option is useful when you are reading several planet-type aggregators with partially colliding userbase. When disabled, it forces same posts from different feeds to appear only once.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('ENABLE_FEED_CATS', 1, 'false', 'Enable feed categories',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('SHOW_CONTENT_PREVIEW', 1, 'true', 'Show content preview in headlines list',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('SHORT_DATE_FORMAT', 2, 'M d, G:i', 'Short date format',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('LONG_DATE_FORMAT', 2, 'D, M d Y - G:i', 'Long date format',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('COMBINED_DISPLAY_MODE', 1, 'false', 'Combined feed display',2, 'Display expanded list of feed articles, instead of separate displays for headlines and article content');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('HIDE_READ_FEEDS', 1, 'false', 'Hide feeds with no unread messages',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('ON_CATCHUP_SHOW_NEXT_FEED', 1, 'false', 'On catchup show next feed',2, 'When "Mark as read" button is clicked in toolbar, automatically open next feed with unread articles.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('FEEDS_SORT_BY_UNREAD', 1, 'false', 'Sort feeds by unread articles count',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('REVERSE_HEADLINES', 1, 'false', 'Reverse headline order (oldest first)',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('DIGEST_ENABLE', 1, 'false', 'Enable e-mail digest',1, 'This option enables sending daily digest of new (and unread) headlines on your configured e-mail address');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('CONFIRM_FEED_CATCHUP', 1, 'true', 'Confirm marking feed as read',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('CDM_AUTO_CATCHUP', 1, 'false', 'Automatically mark articles as read',3, 'This option enables marking articles as read automatically while you scroll article list.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_DEFAULT_VIEW_MODE', 2, 'adaptive', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_DEFAULT_VIEW_LIMIT', 3, '30', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_PREFS_ACTIVE_TAB', 2, '', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('STRIP_UNSAFE_TAGS', 1, 'true', 'Strip unsafe tags from articles', 3, 'Strip all but most common HTML tags when reading articles.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('BLACKLISTED_TAGS', 2, 'main, generic, misc, uncategorized, blog, blogroll, general, news', 'Blacklisted tags', 3, 'When auto-detecting tags in articles these tags will not be applied (comma-separated list).');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('FRESH_ARTICLE_MAX_AGE', 3, '24', 'Maximum age of fresh articles (in hours)',2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('DIGEST_CATCHUP', 1, 'false', 'Mark articles in e-mail digest as read',1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('CDM_EXPANDED', 1, 'true', 'Automatically expand articles in combined mode',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('PURGE_UNREAD_ARTICLES', 1, 'true', 'Purge unread articles',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('HIDE_READ_SHOWS_SPECIAL', 1, 'true', 'Show special feeds when hiding read feeds',3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('VFEED_GROUP_BY_FEED', 1, 'false', 'Group headlines in virtual feeds',2, 'When this option is enabled, headlines in Special feeds and Labels are grouped by feeds');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('STRIP_IMAGES', 1, 'false', 'Do not show images in articles', 2);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_DEFAULT_VIEW_ORDER_BY', 2, 'default', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('ENABLE_API_ACCESS', 1, 'false', 'Enable external API', 3);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_SPECIAL', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_LABELS', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_UNCAT', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_COLLAPSED_FEEDLIST', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_ENABLE_CATS', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_SHOW_IMAGES', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_HIDE_READ', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_SORT_FEEDS_UNREAD', 1, 'false', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_THEME_ID', 2, '0', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('USER_TIMEZONE', 2, 'UTC', 'User timezone', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('SORT_HEADLINES_BY_FEED_DATE', 1, 'true', 'Sort headlines by feed date',3, 'Use feed-specified date to sort headlines instead of local import date.');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('USER_STYLESHEET', 2, '', 'Customize stylesheet', 2, 'Customize CSS stylesheet to your liking');

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id) values('_MOBILE_BROWSE_CATS', 1, 'true', '', 1);

insert into ttrss_prefs (pref_name,type_id,def_value,short_desc,section_id,help_text) values('SSL_CERT_SERIAL', 2, '', 'Login with an SSL certificate',3, 'Click to register your SSL client certificate with tt-rss');

create table ttrss_user_prefs (
	owner_uid integer not null references ttrss_users(id) ON DELETE CASCADE,
	pref_name varchar(250) not null references ttrss_prefs(pref_name) ON DELETE CASCADE,
	profile integer references ttrss_settings_profiles(id) ON DELETE CASCADE,
	value text not null);

create index ttrss_user_prefs_owner_uid_index on ttrss_user_prefs(owner_uid);
-- create index ttrss_user_prefs_value_index on ttrss_user_prefs(value);

create table ttrss_sessions (id varchar(250) unique not null primary key,
	data text,
	expire integer not null);

create index ttrss_sessions_expire_index on ttrss_sessions(expire);

create function SUBSTRING_FOR_DATE(timestamp, int, int) RETURNS text AS 'SELECT SUBSTRING(CAST($1 AS text), $2, $3)' LANGUAGE 'sql';

create table ttrss_feedbrowser_cache (
	feed_url text not null primary key,
	title text not null,
	site_url text not null,
	subscribers integer not null);

create table ttrss_labels2 (id serial not null primary key,
	owner_uid integer not null references ttrss_users(id) ON DELETE CASCADE,
	fg_color varchar(15) not null default '',
	bg_color varchar(15) not null default '',
	caption varchar(250) not null
);

create table ttrss_user_labels2 (
	label_id integer not null references ttrss_labels2(id) ON DELETE CASCADE,
	article_id integer not null references ttrss_entries(id) ON DELETE CASCADE
);

create table ttrss_access_keys (id serial not null primary key,
	access_key varchar(250) not null,
	feed_id varchar(250) not null,
	is_cat boolean not null default false,
	owner_uid integer not null references ttrss_users(id) on delete cascade);

create table ttrss_linked_instances (id serial not null primary key,
	last_connected timestamp not null,
	last_status_in integer not null,
	last_status_out integer not null,
	access_key varchar(250) not null unique,
	access_url text not null);

create table ttrss_linked_feeds (
	feed_url text not null,
	site_url text not null,
	title text not null,
	created timestamp not null,
	updated timestamp not null,
	instance_id integer not null references ttrss_linked_instances(id) ON DELETE CASCADE,
	subscribers integer not null);

commit;
