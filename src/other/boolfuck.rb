# implements "Boolfuck" as described in https://esolangs.org/wiki/BF_instruction_minimalization
# !DIFFERENT! from Boolfuck as detailed here: https://esolangs.org/wiki/Boolfuck

src = File.read(ARGV[0]) rescue ARGV[0]

def getchar
    res = STDIN.getc.ord rescue 0
end

compiled = <<EOT
bits = [0] * 30000
ptr = 0
EOT
tab = " " * 4
indent = 0
compiled += src.scan(/[><]+|[?@\[\].,]/).map { |c|
    prepend = tab * indent
    res = case c[0]
    when ">"
        "ptr += #{c.size}"
    when "<"
        "ptr -= #{c.size}"
    when "["
        indent += 1
        "until bits[ptr].zero?"
    when "]"
        indent -= 1
        prepend = tab * indent
        "end"
    when "@"
        "bits[ptr] = 1 - bits[ptr]"
    when "."
        "print bits[ptr...ptr + 8].join.to_i(2).chr"
    when ","
        "bits[ptr...ptr+8] = getchar.to_s(2).rjust(8, '0').chars.map(&:to_i)"
    else
        "# unimplemented: #{c}"
    end
    res = prepend + res
}.join "\n"

puts compiled
puts "-" * 70
eval compiled