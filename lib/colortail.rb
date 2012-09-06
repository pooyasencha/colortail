require 'rubygems'
require 'thread'
require 'file/tail'

dir = File.dirname(__FILE__) + '/colortail'

require dir + '/application'
require dir + '/configuration'

module ColorTail
    class Colorize
        COLORS = {
            :none => "0",
            :black => "30",
            :red => "31",
            :green => "32",
            :yellow => "33",
            :blue => "34",
            :magenta => "35",
            :cyan => "36",
            :white => "37"
        }
    
        ATTRIBUTES = {
            :bright => 1,
            :dim => 2,
            :underscore => 4,
            :blink => 5,
            :reverse => 7,
            :hidden => 8
        }
    
        attr_accessor :color_matchers
        attr_accessor :previous_color
        attr_accessor :previous_attribute

        def initialize()
            # This is an instance variable in case we tail
            # multiple files with different groupings
            @color_matchers = Array.new
            @previous_color = :none
            @previous_attribute = nil
        end

        def log(filename, message, line_prefix=nil)
            # Add the filename to the message
            message = "#{message}"

            color = :none
            attribute = nil

            @color_matchers.each do |filter|
                if message =~ filter[:match]
                        # color
                        if filter[:color] == :previous
                            color = @previous_color
                        else
                            color = filter[:color]
                            @previous_color = color
                        end

                        #attribute
                        if filter[:attribute] == :previous
                            attribute = @previous_attribute
                        else
                            attribute = filter[:attribute]
                            @previous_attribute = attribute
                        end

                        message = message.strip if filter[:strip]
                        message = filter[:prepend] + message unless filter[:prepend].nil?
                        break
                end
            end

            if color != :hide
                current_color = COLORS[color]
                current_attribute = ATTRIBUTES[attribute]

                line_prefix = colorit(line_prefix.to_s, current_color, current_attribute, nil) unless line_prefix.nil?
                show(colorit(message, current_color, current_attribute), line_prefix)
            end
        end

        def show(message,prefix)
            puts "#{prefix}#{message}"
        end
    
        def colorit(message, color, attribute, nl = "\n")
            attribute = "#{attribute};" if attribute
            "\e[#{attribute}#{color}m" + message.gsub(/[\r\n]?$/, '') + "\e[0m#{nl}"
        end

        def add_color_matcher( options )
            @color_matchers.push( options )
        end
    end


    class TailFile < File
        include File::Tail
    end
end
