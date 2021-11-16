require_relative "four-compiler.rb"
class FourPretifier < FourCompiler
    @@indent = "  "
    def initialize(prog, verbose: false)
        super(prog)
        @output = [["3."]]
        @depth = 1
        @verbose = verbose
    end
    def add_line(line, if_verbose="")
        @output.push [line, if_verbose].map { |e| @@indent * @depth + e }
    end
    
    def ref(a)
        "$#{a}"
    end
    def val(a)
        "#{a.to_i}"
    end
    
    def compile_addition(target, a, b)
        add_line "0 #{target} #{a} #{b}", "#{ref target} = #{ref a} + #{ref b}"
    end
    def compile_subtraction(target, a, b)
        add_line "1 #{target} #{a} #{b}", "#{ref target} = #{ref a} - #{ref b}"
    end
    def compile_multiplication(target, a, b)
        add_line "2 #{target} #{a} #{b}", "#{ref target} = #{ref a} * #{ref b}"
    end
    def compile_division(target, a, b)
        add_line "3 #{target} #{a} #{b}", "#{ref target} = #{ref a} / #{ref b}"
    end
    def compile_exit
        add_line "4", "exit"
    end
    def compile_output(target)
        add_line "5 #{target}", "print #{ref target}"
    end
    def compile_set(target, value)
        add_line "6 #{target} #{value}", "#{ref target} := #{val value}"
    end
    def compile_input(target)
        add_line "7 #{target}", "#{ref target} := input()"
    end
    def compile_begin_loop(target)
        add_line "8 #{target}", "while(#{ref target} != 0) do"
        @depth += 1
    end
    def compile_end_loop
        @depth -= 1
        add_line "9", "end"
    end
    def compile_finish
        @output.push ["4"]
        if @verbose
            max_size = @output.map { |a, b| a.size } .max
            max_size += 4
            @output.map! { |a, b|
                a.ljust(max_size) + (b.nil? || b.empty? ? "" : "; " + b)
            }
        else
            @output.map! { |e| e[0] }
        end
        @output.map { |e| e } .join "\n"
    end
end