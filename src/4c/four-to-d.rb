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
    def compile_exit
        add_line "return;"
    end
    def compile_output(target)
        add_line "write(cast(char) #{getvar target});"
    end
    def compile_set(target, value)
        add_line "#{getvar target} = #{value.to_i};"
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