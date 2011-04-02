#include <amxmodx>
#include <amxmisc>

#define PLUGIN   	"SuperMotd"
#define AUTHOR		"timmw"
#define VERSION		"0.1.0"

// Maximum characters in style.css
#define MAX_CSS_FILE_SIZE 512

// A buffer to hole the contents of /configs/supermotd/templates/style.css
new g_CSSCache[MAX_CSS_FILE_SIZE] = ""

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /help", "ShowHelp")
	register_clcmd("say_team /help", "ShowHelp")
	
	register_clcmd("say", "SayHandler")
	register_clcmd("say_team", "SayHandler")
	
	register_clcmd("smotd_purge_cache", "PurgeCache", ADMIN_RCON, "Purge the cache files.")
}

public plugin_end()
{
	PurgeCache()
}

// Read the style.css into a string and place it in g_CSSCache
public GetCSS()
{
	new CSSPath[128]
	get_configsdir(CSSPath, 127)
	formatex(CSSPath, 127, "%s/supermotd/templates/style.css", CSSPath)
	
	new line = 0, textline[256], len, content[512]
	while((line = read_file(CSSPath, line, textline, 255, len)))
	{
		add(content, 511, textline)
	}
	
	trim(content)
	replace_all(content, 511, "^t", "")
	
	copy(g_CSSCache, 511, content)
}

public PurgeCache()
{
	new cacheDir[128]
	get_configsdir(cacheDir, 127)
	formatex(cacheDir, 127, "%s/supermotd/cache/", cacheDir)
	
	new fileName[64]
	new dh = open_dir(cacheDir, fileName, 63)
	while(next_file(dh, fileName, 63))
	{
		if(equal(fileName, ".") || equal(fileName, ".."))
		{
			continue
		}
		new cachePath[128]
		copy(cachePath, 127, cacheDir)
		add(cachePath, 127, fileName)
		
		if(delete_file(cachePath) == 0)
		{
			log_amx("Failed to delete cache file: %s", cachePath)
		}
		else
		{
			log_amx("Cache file deleted: %s", cachePath)
		}
	}
	
	return PLUGIN_HANDLED
}

public ShowHelp(id)
{
	new helpFileCachePath[64]
	get_configsdir(helpFileCachePath, 63)
	format(helpFileCachePath, 63, "%s/supermotd/cache/help.html", helpFileCachePath)
	
	if(file_exists(helpFileCachePath) == 0)
	{
		new templateDir[64]
		get_configsdir(templateDir, 63)
		format(templateDir, 63, "%s/supermotd/templates/", templateDir)
	
		new fileName[64]
		new dh = open_dir(templateDir, fileName, 63)
		
		new cmds[256]
		while(next_file(dh, fileName, 63))
		{
			if(equal(fileName, ".") || equal(fileName, "..") || equal(fileName, "style.css"))
			{
				continue
			}
			trim(fileName)		
			replace(fileName, 63, ".html", "<br />")
			
			new cmd[32]
			formatex(cmd, 255, "/%s<br/>", fileName)
			add(cmds, 255, cmd)
		}
		close_dir(dh)
		
		write_file(helpFileCachePath, cmds)
		
		log_amx("Help cache file created.")
	}
	
	show_motd(id, helpFileCachePath)
}

public SayHandler(id)
{
	new tpl[191]
	read_args(tpl, 190)
	remove_quotes(tpl)
	trim(tpl)
	
	replace(tpl, 190, "/", "")
	add(tpl, 63, ".html")
	
	new configsDir[64], tplPath[64]
	get_configsdir(configsDir, 63)
	
	format(tplPath, 63, "%s/supermotd/templates/%s", configsDir, tpl)
	
	// If template file exists
	if(file_exists(tplPath))
	{
		// Find out if it's been cached
		new cachePath[64]
		format(cachePath, 63, "%s/supermotd/cache/%s", configsDir, tpl)
		
		if(file_exists(cachePath))
		{
			// If it has been cached
			show_motd(id, cachePath)
		}
		else
		{
			// If it hasn't been cached
			CreateCacheFile(tplPath, cachePath)
			show_motd(id, cachePath)
		}
	}

	return PLUGIN_CONTINUE
}

public CreateCacheFile(tplPath[], cachePath[])
{	
	new line = 0, textline[256], len, content[2000]
	while((line = read_file(tplPath, line, textline, 255, len)))
	{
		add(content, 1999, textline)
	}
	
	GetCSS()
	
	// Insert the styles into the motd string
	replace(content, 1999, "{stylesheet}", g_CSSCache)
	
	replace(content, 1999, "{plugin}", PLUGIN)
	replace(content, 1999, "{author}", AUTHOR)
	
	// Remove all tabs from the motd string
	replace_all(content, 1999, "^t", "")
	
	trim(content)
	
	write_file(cachePath, content)
	
	log_amx("Cache file created: %s", cachePath)
}