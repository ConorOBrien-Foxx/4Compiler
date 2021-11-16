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