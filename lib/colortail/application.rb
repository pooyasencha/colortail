module ColorTail

    class Application
        class << self
            def run!(*arguments)
               opt = ColorTail::Options.new(arguments) 
               files = opt[:files]
               options = opt[:options]
    
               # Deal with any/all options issues
               if options[:invalid_argument]
                   $stderr.puts options[:invalid_argument]
                   options[:help] = true
               end
    
               if options[:help]
                   $stderr.puts opt.opts
                   return 1
               end
    
               begin
                   # Read the config file if it exists
                   if File.exists?(options[:conf])
                       config = ColorTail::Configuration.new(options[:conf])
                       @match_group = config.load_opts(options[:group])
                   else
                       # Create this to ensure we always have a value for this array
                       @match_group = Array.push( 'default' => [] )
                   end

                   # Display the list of available groups and exit
                   if options[:list]
                       config.display_match_groups()
                       return 1
                   end
    
                   logger = ColorTail::Colorize.new()

                   # Add the color match array if we aren't using the default
                   if @match_group.class == Array
                       @match_group.each do |matcher|
                           logger.add_color_matcher( matcher )
                       end
                   else
                       logger.add_color_matcher( @match_group )
                   end
    
                   # Create a thread for each file
                   threads = []
                   files.each do |file|
                       threads[files.index(file)] = Thread.new {
                           tailer = ColorTail::TailFile.new( file )
    
                           # First display the last 10 lines of each file in ARGV
                           tailer.interval = 10
                           tailer.backward( 10 )
    
                           # Tail the file and show new lines
                           tailer.tail { |line|  logger.log( file, line ) }
                       }
                       threads[files.index(file)].run
                   end

                   # Let the threads do their real work
                   threads.each do |thread|
                       thread.join
                   end

               # If we get a CTRL-C, catch it (rescue) and send it for cleanup
               rescue Interrupt
                   cleanup(threads)
               end

               return 0
            end

            def cleanup(threads)
                threads.each do |thread|
                    thread.kill
                end
                $stderr.puts "Terminating..."
                exit
            end
        end
    end


    class FileDoesNotExist < StandardError
    end

end
