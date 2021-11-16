#!/usr/bin/ruby
# translate pseudocode to 4

require_relative '4.rb'

# memory:
# 00-19     constants
# 20-59     variables
# 60-69     if-temps
# 90-99     functional spaces

# TODO: optimize constants

class String
    def num_pred
        # (self.to_i - 1).to_s.rjust(2, ?0)
    end
    
    def num_pred!
        pred = num_pred
        self.clear
        self << pred
    end
end

class Macro
    attr_reader :name, :params, :lines
    def initialize(name, params)
        @name = name
        @params = params
        @lines = []
    end
    
    def add(line)
        @lines << line
    end
    
    def replace(args, replacements)
        if @params.size != replacements.size
            raise "Macro #{@name} called with insufficient parameters (expected #{@params.size}, got #{replacements.size})"
        end
        args.map { |arg|
            index = @params.find_index { |par| arg == par }
            if index.nil?
                arg
            else
                replacements[index]
            end
        }
    end
    
    def inspect
        "Macro(#{@name}, #{@params}, #{@lines.map(&:inspect) * ";; "})"
    end
end

class Four
    @@identifier = /[A-Za-z][_A-Za-z0-9]*/
    @@param = /\d+|#{@@identifier}|'(?:\\?.|\s)'/
    def initialize(program)
        @program = program
        @result = ""
        @variables = {}
        @cur_num = "00"
        @constants = []
        @cur_var = "20"
        @cur_fnc = "90"
        @end_types = []
        @ifs_available = ("60".."69").to_a
        @lines = @program.lines
        @pre = ""
        
        @macros = {}
        @macro_build = nil
    end
    
    def Four.translate(program)
        inst = Four.new program
        inst.run
        inst.finish.gsub(/\s+/, " ")
    end
    
    def finish
        @result += "4"
        @result = "3. " + @pre + @result
        @result.dup
    end
    
    def def_var(name, value)
        compile gen_number get_variable(name), value
    end
    
    # assigns the value in `str` to reference
    def gen_number(reference, str)
        # p [reference, str]
        res = ""
        case str
            when /^'(.)'$/
                res = gen_number(reference, $1.ord.to_s)
            when /^'(\\.)'$/
                res = gen_number(reference, eval("\"#$1\"").ord.to_s)
            when /^\d{1,2}$/
                # p [reference, str, str.rjust(2, ?0)]
                res += "6" + reference + str.rjust(2, ?0)
            when /^\d{3,}$/
                repetend, num = str.to_i.divmod 99
                res += "6" + reference + num.to_s.rjust(2, ?0)
                repetend.times {
                    # p "99 is #{get_value("99")}"
                    res += "0" + reference * 2 + get_value("99")
                }
            when /^#{@@identifier}$/
                # zero the reference
                res += "6" + reference + "00"
                # add the str to the reference
                res += "0" + reference + reference + get_variable(str)
            else
                $stderr.puts "Unhandled thing in gen_number #{str.inspect}"
                exit
        end
        res
    end
    
    def get_variable(name)
        unless @variables.has_key? name
            raise "No such variable declared `#{name}'."
            exit 3
        end
        @variables[name]
    end
    
    def get_value(str, defnum=true)
        # p [str, defnum]
        case str
            when /^\d+$/
                int_val = str.to_i
                index = @constants.index int_val
                # p [str, !index.nil?]
                unless index.nil?
                    # p "cache hit: #{str}"
                    index.to_s.rjust(2, ?0)
                else
                    if @cur_num >= "20"
                        STDERR.puts "Exceeded maximum constant limit"
                        exit -3
                    end
                    str = str.rjust(2, ?0)
                    ident = @cur_num.dup
                    @cur_num.next!
                    @constants << int_val
                    precompile gen_number ident, str
                    # p @constants
                    ident
                end
            when /^'(.)'$/
                get_value $1.ord.to_s, defnum
            when /^'(\\.)'$/
                get_value eval($&).ord.to_s, defnum
            when /^#{@@identifier}$/
                @variables[str]
            else
                $stderr.puts "idk what to do with #{str.inspect}"
                nil
        end
    end
    
    def compile(str)
        @result += str
    end
    
    def precompile(str)
        @pre += str
    end
    
    # three references
    def comp_compare(target, a, b)
        orig = @cur_fnc.dup
        
        temp_a = @cur_fnc.dup
        @cur_fnc.next!
        
        # set temp_a, a
        comp_set temp_a, "00"
        comp_add temp_a, temp_a, a
        
        # subx temp_a, b
        comp_subtract temp_a, temp_a, b
        
        # square temp_a
        comp_multiply temp_a, temp_a, temp_a
        
        # set target, 1
        comp_set target, "01"
        
        # loop temp_a
        comp_loop temp_a
        
        #   set target, 0
        comp_set target, "00"
        
        #   set temp_a, 0
        comp_set temp_a, "00"
        
        # end
        comp_loop_end
        
        # restore temporary
        @cur_fnc = orig
    end
    
    def comp_mod(target, a, b)
        if target == a
            # p 'temp needed'
            # we need a temporary
            orig = @cur_fnc.dup
            
            temp_a = @cur_fnc.dup
            @cur_fnc.next!
            
            comp_mod temp_a, a, b
            comp_set a, "00"
            comp_add a, a, temp_a
            
            # restore temporary
            @cur_fnc = orig
        else
            # p [target, a, b]
            comp_divide target, a, b
            comp_multiply target, target, b
            comp_subtract target, a, target
        end
    end
    
    def comp_exit
        compile "4"
    end
    
    def comp_input(target)
        compile "7" + target
    end
    
    def comp_loop(target)
        compile "8" + target
        @end_types.push lambda { "" }
    end
    
    def comp_if(target)
        if_tmp = @ifs_available.shift
        compile "6" + if_tmp + "00"
        compile "0" + if_tmp * 2 + target
        compile "8" + if_tmp
        @end_types.push lambda {
            @ifs_available.unshift if_tmp
            "6" + if_tmp + "00"
        }
    end
    
    def comp_loop_end
        compile @end_types.pop[]
        compile "9"
    end
    
    def comp_set(source, dest)
        compile "6" + source + dest
    end
    
    def comp_print(source)
        compile "5" + source
    end
    
    def comp_add(target, a, b)
        compile "0" + target + a + b
    end
    
    def comp_divide(target, a, b)
        compile "3" + target + a + b
    end
    
    def comp_multiply(target, a, b)
        compile "2" + target + a + b
    end
    
    def comp_subtract(target, a, b)
        compile "1" + target + a + b
    end
    
    # NOTE: grossly uncompressed.
    def comp_write(string)
        orig = @cur_fnc.dup
        
        temp_main = @cur_fnc.dup
        @cur_fnc.next!
        # temp_aux = @cur_fnc.dup
        # @cur_fnc.next!
        
        ords = string.chars.map(&:ord)
        
        
        ords.each { |o|
            compile gen_number temp_main, o.to_s
            comp_print temp_main
            compile " "
        }
        
        # restore temporary
        @cur_fnc = orig
    end
    
    def compile_macro(macro, replacements)
        macro.lines.each { |command, args, line|
            args = macro.replace(args, replacements)
            # p [command, args, line]
            # p @variables
            compile_command command, args, line
        }
    end
    
    def compile_command(command, args, line=nil)
        case command
        when "decl"
            args.each { |e|
                @variables[e] = @cur_var.dup
                @cur_var.next!
            }
            
        when "set"
            target, value = args
            def_var(target, value)
            
        when "print"
            args.each { |target|
                comp_print get_value(target)
            }
            
        when "add"
            target, a, b = args
            comp_add get_variable(target), get_value(a), get_value(b)
        when "addx"
            target, b = args
            comp_add get_variable(target), get_variable(target), get_value(b)
        when "inc"
            target, = args
            comp_add get_variable(target), get_variable(target), get_value("01")
            
        when "sub"
            target, a, b = args
            comp_subtract get_variable(target), get_value(a), get_value(b)
        when "subx"
            target, b = args
            comp_subtract get_variable(target), get_variable(target), get_value(b)
        when "dec"
            target, = args
            comp_subtract get_variable(target), get_variable(target), get_value("01")
        when "zero"
            target, = args
            comp_set get_variable(target), "00"
        when "neg"
            target, = args
            comp_subtract get_variable(target), get_value("00"), get_variable(target)
            
        when "mul"
            target, a, b = args
            comp_multiply get_variable(target), get_value(a), get_value(b)
        when "mulx"
            target, b = args
            comp_multiply get_variable(target), get_variable(target), get_value(b)
        when "square"
            target, = args
            comp_multiply get_variable(target), get_variable(target), get_variable(target)
            
        when "div"
            target, a, b = args
            comp_divide get_variable(target), get_value(a), get_value(b)
        when "divx"
            target, b = args
            comp_divide get_variable(target), get_variable(target), get_value(b)
            
        when "cmp"
            target, a, b = args
            comp_compare get_variable(target), get_value(a), get_value(b)
        
        when "mod"
            target, a, b = args
            comp_mod get_variable(target), get_value(a), get_value(b)
        when "modx"
            target, b = args
            comp_mod get_variable(target), get_variable(target), get_value(b)
            
        when "loop"
            target, = args
            comp_loop get_variable(target)
        when "if"
            target, = args
            comp_if get_variable(target)
        when "end"
            comp_loop_end
            
        when "input"
            target, = args
            comp_input get_variable(target)
            
        when "msg"
            str = line[5..-2].gsub(/""/,'"')
            comp_write str
            
        when "puts"
            str = (line[6..-2] || "").gsub(/""/,'"')
            comp_write str unless str.empty?
            comp_print get_value("10")
        
        when "ret", "exit"
            comp_exit
        
        when "const"
            raise "Unimplemented: const"
        
        else
            print "no such command #{command}"
        end
    end
    
    def run
        mode = :compile
        # :interpret
        @lines.each { |line|
            line.gsub!(/((?:'..?'|"(?:.|"")+"|.)*?);.+/, '\1')
            line.strip!
            next if line.empty?
            # p line
            # preprocess
            
            if /^#(\w+)\s*(.*)/ === line
                case $1
                when "define"
                    mode = :preprocess
                    if /(\w+)\((.+)\)/ === $2
                        @macro_build = Macro.new $1, $2.split(/,\s*/)
                    else
                        STDERR.puts "Malformed: #{line}"
                    end
                when "enddef"
                    mode = :compile
                    @macros[@macro_build.name] = @macro_build
                    @macro_build = nil
                when *@macros.keys
                    macro = @macros[$1]
                    args = $2.gsub(/^\(|\)$/, "").scan(@@param)
                    if mode == :preprocess
                        # p macro
                        # p @macro_build
                        # p args
                        # puts "````"*3
                        macro.lines.each { |line|
                            @macro_build.add [line[0], macro.replace(line[1], args), line[2]]
                        }
                        # puts "`"*40
                    else
                        compile_macro macro, args
                        compile " "
                    end
                else
                    STDERR.puts "Unhandled #command: #{line}"
                end
                next
            end
            
            
            _, command, args = line.match(/^(\w+)\s*((?:(?:#{@@param}),?\s*)+)?/).to_a
            next if command.nil?
            args = (args || "").scan(@@param)
            
            if mode == :preprocess
                @macro_build.add [command, args, line]
                next
            end
            
            compile_command command, args, line
            compile " "
        }
    end
end

prog = Four.translate File.read(ARGV[0])

puts prog if ARGV[1]

dat = 4.(prog)
# puts
# puts "-"*30
# p dat