require 'readline'

# Check to determine whether we're on a windows or linux/os-x host,
# later on we use this to launch ansible in the supported way
# source: https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable? exe
        }
    end
    return nil
end

def ensure_plugins(plugins)
  logger = Vagrant::UI::Colored.new
  result = false

  plugins.each do |p|
    pm = Vagrant::Plugin::Manager.new(
      Vagrant::Plugin::Manager.user_plugins_file
    )
    plugin_hash = pm.installed_plugins
    next if plugin_hash.has_key?(p)
    result = true
    logger.warn("Installing plugin #{p}")
    pm.install_plugin(p)
  end

  if result
    logger.warn("Plugins installed successfully!")
    logger.warn("Re-running \"vagrant up\"")
    exec("vagrant up")
  end
end

def missing_plugins(plugins)
  missing = []

  plugins.each do |p|
    pm = Vagrant::Plugin::Manager.new(
      Vagrant::Plugin::Manager.user_plugins_file
    )
    plugin_hash = pm.installed_plugins
    next if plugin_hash.has_key?(p)
    missing << p
  end

  missing
end

def prompt(prompt="", newline=false)
  prompt += "\n" if newline
  Readline.readline(prompt, true).squeeze(" ").strip
end

def should_install?
  input = prompt "[Y]es/[N]o/[D]on't ask me again: "

  case input.downcase[0]
    when 'y'
      return true
    when 'n'
      return false
    when 'd'
      File.open(".dont-ask-again", "w") {}
      return false
    else
      should_install?
  end
end

def require_plugins(plugins)
  if not File.file?(".dont-ask-again") and not (missing = missing_plugins(plugins)).empty?
    puts "The following plugins are missing:"
    puts missing.join(", ")
    puts "Automatically install missing plugins?"
    ensure_plugins(plugins) if should_install?
  end
end
