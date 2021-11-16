# allows annotated source code
class FourCompiler
    @@arities = [3, 3, 3, 3, 0, 1, 2, 1, 1, 0]
    @@methods = [
        :compile_addition,
        :compile_subtraction,
        :compile_multiplication,
        :compile_division,
        :compile_exit,
        :compile_output,
        :compile_set,
        :compile_input,
        :compile_begin_loop,
        :compile_end_loop,
    ]
    def initialize(prog)
        prog = prog.gsub(/\s+|;.*$/, "")
        unless /^3\./ === prog
            raise "Program must begin with '3.'"
        end
        unless /4$/ === prog
            raise "Program must end with '4'"
        end
        unless /^3\.(\d*)4$/ === prog
            raise "Program must consist of only digits, whitespace, or comments"
        end
        @prog = $1
        @ops = nil
        @noisy = true
    end
    def silence(to=false)
        @noisy = to
    end
    
    def parse
        return unless @ops.nil?
        @prog = @prog
        @ops = []
        pc = 0
        while pc < @prog.size
            op = @prog[pc].to_i
            arity = @@arities[op]
            pc += 1
            operands = @prog.slice(pc, arity * 2)
                .chars
                .each_slice(2)
                .map { |e| e.join }
            @ops << [op, operands]
            pc += arity * 2
        end
    end
    
    @@methods.each { |name|
        define_method(name) { |*operands|
            raise "Unimplemented: #{name}" if @noisy
        }
    }
    
    # usually returns a string
    def compile_finish
        self
    end
    
    def compile
        parse
        @ops.each { |op, operands|
            # p op
            send @@methods[op], *operands
        }
        compile_finish
    end
end

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

class FourToD < FourCompiler
    @@indent = "    "
    def initialize(prog)
        super(prog)
        @variables = []
        @output = []
        @depth = 1
    end
    def add_line(line)
        @output.push @@indent * @depth + line
    end
    
    def varname(cell)
        "c#{cell}"
    end
    
    def getvar(target)
        name = varname target
        @variables << name unless @variables.include? name
        name
    end
    
    def compile_op(op, target, a, b)
        if target == a
            add_line "#{getvar target} #{op}= #{getvar b};"
        else
            add_line "#{getvar target} = #{getvar a} #{op} #{getvar b};"
        end
    end
    
    def compile_set(target, value)
        add_line "#{getvar target} = #{value.to_i};"
    end
    def compile_addition(target, a, b)
        compile_op '+', target, a, b
    end
    def compile_subtraction(target, a, b)
        compile_op '-', target, a, b
    end
    def compile_multiplication(target, a, b)
        compile_op '*', target, a, b
    end
    def compile_division(target, a, b)
        compile_op '/', target, a, b
    end
    def compile_output(target)
        add_line "write(cast(char) #{getvar target});"
    end
    def compile_input(target)
        add_line "#{getvar target} = getchar();"
    end
    def compile_begin_loop(target)
        add_line "while(#{getvar target} != 0) {"
        @depth += 1
    end
    def compile_end_loop
        @depth -= 1
        add_line "}"
    end
    def compile_exit
        add_line "return;"
    end
    
    def compile_finish
        header = ""
        @variables.sort.each_slice(10) { |slice|
            header += if header.empty?
                "#{@@indent}BigInt "
            else
                "#{@@indent}       "
            end
            header += slice.join ", "
            header += ",\n"
        }
        header.chomp!
        header.chop! # remove ,\n
        header += ";"
        @output.unshift header unless header.empty?
        joined = @output.join "\n"
        "import std.stdio;\nimport std.bigint;\n\nvoid main() {\n#{joined}\n}"
    end
end

compiler = nil

case ARGV[0].downcase
when "d"
    compiler = FourToD
when "pretty", "pp", "p"
    compiler = FourPretifier
else
    STDERR.puts "Invalid compiler target: #{ARGV[0]}"
    exit 2
end
a = compiler.new File.read(ARGV[1])#, verbose: true
puts a.compile