# modified from https://gist.github.com/0x0dea/db1b66344a7970a18373

$ops = %w(add subtract multiply divide exit print set input loop end)

# EDIT: provides proper EOF
def getchar
    res = STDIN.getc.ord rescue 0
end

# EDIT: update Fixnum to Numeric as per modern ruby
class Numeric
  def call prog
    return unless self == 4
    unless prog = prog.delete(' ')[/\A3\.(\d*)4\z/, 1]
      raise SyntaxError, "Program must begin '3.' and end '4'.", caller
    end

    arity = [3, 3, 3, 3, 0, 1, 2, 1, 1, 0]
    cells = [i = pc = 0] * 100
    insns, loops, stack = [], {}, []

    while c = prog[pc]
      op = c.to_i
      insns << [op, arity[op].times.map {
        prog[(pc += 1)..(pc += 1)].to_i
      }]
      stack << i if op == 8
      loops[loops[i] = stack.pop] = i if op == 9
      i  += 1
      pc += 1
    end
    ip = -1
    while (ip += 1) < insns.size
      op, (a, b, c) = insns[ip]
      case op
      when 0..3; cells[a] = cells[b].send '+-*/'[op], cells[c]
      when 4; exit
      when 5; print cells[a].chr
      # when 5; puts cells[a]
      when 6; cells[a] = b
      when 7; cells[a] = getchar
      when 8; ip = loops[ip] if cells[a] == 0
      when 9; ip = loops[ip] - 1 # EDIT: fixes loop condition
      end
    end
    {
        stack: stack,
        cells: cells,
    }
  end
end