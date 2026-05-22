# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# runtime.rb has been released under MIT (*only this file*).

# Contributors outside of DragonRuby who also hold Copyright:
# - Kevin Fischer: https://github.com/kfischer-okarin

module GTK
  class Runtime
    module Require
      def require file
        if !@production && file == "app/main.rb"
          @user_modules = []
        end
        # add .rb extension if the require path doesn't
        # end with rb.
        file_metadata = get_require_metadata file
        file = file_metadata[:output_file]

        if @debug_require
          log "REQUIRE: Started for =#{file}=.".indent(@require_stack.length, indent_char: "*", pad_line_with_space: true)
        end

        if !file_metadata[:file_exist]
          raise "#{file} does not exist."
        end

        ext = File.extname(file)
        if (ext == '.rb') and @ffi_file.path_exists(file + 'c')
          file = file + 'c'
        else
          raise "#{file} does not exist." unless @ffi_file.path_exists file
        end

        if !file.end_with?(".rbc")
          syntax = (@ffi_file.read file) || ''
          syntax_check_result = @ffi_mrb.parse syntax
          okay = (syntax_check_result == "Syntax OK")
          if !okay
            raise <<~S
          ** Failed to load #{file}.
          #{syntax_check_result}

          S
          else
            add_to_require_queue file
          end
        else
          add_to_require_queue file
        end

        @required_files << file
        @required_files.uniq!
        __require_sync__ file

        if @debug_require
          log "REQUIRE: Completed for =#{file}=.".indent(@require_stack.length, indent_char: "*", pad_line_with_space: true)
        end

        if !@production && file == "app/main.rb"
          ObjectSpace.each_object(Module) do |klass|
            core_modules_to_s = {}
            @core_modules.each do |core_module|
              core_modules_to_s[core_module.name.to_s] = true
            end

            if !core_modules_to_s[klass.name.to_s]
              @user_modules << klass
            end
          end
        end
      rescue Exception => e
        raise LoadError.new(file, e, "* ERROR: Exception while requiring #{file}.\n#{e}\n#{e.__backtrace_to_org__}")
      end

      def require_relative file
        if @debug_require
          log "REQUIRE RELATIVE: Started for =#{file}=.".indent(@require_stack.length, indent_char: "*", pad_line_with_space: true)
        end

        current_require_file = @require_stack.last || "app/main.rb"
        current_require_path = File.dirname current_require_file
        current_require_path = '' if current_require_path == '.'
        full_path = File.join current_require_path, file
        require full_path

        if @debug_require
          log "REQUIRE RELATIVE: Completed for =#{file}=.".indent(@require_stack.length, indent_char: "*", pad_line_with_space: true)
        end
      end

      def purge_user_global_variables
        return if @production
        global_variables.each do |var|
          if !@core_global_variables.include? var
            puts "setting #{var} to nil"
            var_name = var.to_s
            eval("#{var_name} = nil")
          end
        end
      end

      def purge_user_modules
        return if @production
        $gtk.ivar(:user_modules).each do |klass|
          puts "purging #{klass.name}"
          Object.purge_class klass.name.to_sym
        end
      end
    end
  end
end

module GTK
  class Runtime
    include Require
  end
end

class Object
  def require file
    $gtk.require file
  end

  def require_relative file
    $gtk.require_relative file
  end
end
