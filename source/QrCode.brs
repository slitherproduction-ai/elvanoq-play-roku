' Codificador QR minimo para a tela de ativacao.
' Modo byte, versao 4 (33x33), correcao L: ate 78 bytes ASCII.
' Retorna uma matriz [linha][coluna] com 1 = modulo escuro, ou invalid se o texto nao couber.

function qrXor(a as Integer, b as Integer) as Integer
    return (a or b) and not (a and b)
end function

function qrMatrix(text as String) as Object
    SIZE = 33
    DATA_CW = 80
    ECC_CW = 20
    if len(text) > 78 then return invalid

    ' --- tabelas GF(256)
    gfExp = []
    gfLog = []
    for i = 0 to 511
        gfExp.push(0)
        if i < 256 then gfLog.push(0)
    end for
    x = 1
    for i = 0 to 254
        gfExp[i] = x
        gfLog[x] = i
        x = x * 2
        if x >= 256 then x = qrXor(x, &h11D)
    end for
    for i = 255 to 511
        gfExp[i] = gfExp[i - 255]
    end for

    ' --- fluxo de bits: modo byte (0100) + tamanho (8 bits) + dados
    bits = []
    qrPushBits(bits, 4, 4)
    qrPushBits(bits, len(text), 8)
    for i = 1 to len(text)
        qrPushBits(bits, asc(mid(text, i, 1)) and 255, 8)
    end for
    terminator = DATA_CW * 8 - bits.count()
    if terminator > 4 then terminator = 4
    for i = 1 to terminator
        bits.push(0)
    end for
    while bits.count() mod 8 <> 0
        bits.push(0)
    end while
    codewords = []
    for i = 0 to bits.count() - 1 step 8
        value = 0
        for j = 0 to 7
            value = value * 2 + bits[i + j]
        end for
        codewords.push(value)
    end for
    padIndex = 0
    while codewords.count() < DATA_CW
        if padIndex mod 2 = 0 then codewords.push(&hEC) else codewords.push(&h11)
        padIndex = padIndex + 1
    end while

    ' --- Reed-Solomon
    gen = [1]
    for i = 0 to ECC_CW - 1
        nextGen = []
        for j = 0 to gen.count()
            nextGen.push(0)
        end for
        for j = 0 to gen.count() - 1
            nextGen[j] = qrXor(nextGen[j], gen[j])
            nextGen[j + 1] = qrXor(nextGen[j + 1], qrMul(gen[j], gfExp[i], gfExp, gfLog))
        end for
        gen = nextGen
    end for
    work = []
    for each value in codewords
        work.push(value)
    end for
    for i = 1 to ECC_CW
        work.push(0)
    end for
    for i = 0 to DATA_CW - 1
        coef = work[i]
        if coef <> 0 then
            for j = 1 to gen.count() - 1
                work[i + j] = qrXor(work[i + j], qrMul(gen[j], coef, gfExp, gfLog))
            end for
        end if
    end for
    allBits = []
    for each value in codewords
        qrPushBits(allBits, value, 8)
    end for
    for i = DATA_CW to DATA_CW + ECC_CW - 1
        qrPushBits(allBits, work[i], 8)
    end for

    ' --- padroes fixos e areas reservadas
    base = qrEmpty(SIZE, -1)
    qrFinder(base, 0, 0, SIZE)
    qrFinder(base, 0, SIZE - 7, SIZE)
    qrFinder(base, SIZE - 7, 0, SIZE)
    for i = 8 to SIZE - 9
        base[6][i] = (i + 1) mod 2
        base[i][6] = (i + 1) mod 2
    end for
    for r = -2 to 2
        for c = -2 to 2
            ar = abs(r)
            ac = abs(c)
            if ar < ac then ar = ac
            if ar = 1 then base[26 + r][26 + c] = 0 else base[26 + r][26 + c] = 1
        end for
    end for
    base[SIZE - 8][8] = 1
    for i = 0 to 8
        if base[8][i] = -1 then base[8][i] = 0
        if base[i][8] = -1 then base[i][8] = 0
    end for
    for i = 0 to 7
        if base[8][SIZE - 1 - i] = -1 then base[8][SIZE - 1 - i] = 0
        if base[SIZE - 1 - i][8] = -1 then base[SIZE - 1 - i][8] = 0
    end for

    best = invalid
    bestPenalty = 0
    for mask = 0 to 7
        matrix = qrEmpty(SIZE, 0)
        for r = 0 to SIZE - 1
            for c = 0 to SIZE - 1
                if base[r][c] <> -1 then matrix[r][c] = base[r][c]
            end for
        end for
        index = 0
        upward = true
        col = SIZE - 1
        while col > 0
            if col = 6 then col = col - 1
            for stepIdx = 0 to SIZE - 1
                if upward then r = SIZE - 1 - stepIdx else r = stepIdx
                for k = 0 to 1
                    c = col - k
                    if base[r][c] = -1 then
                        bit = 0
                        if index < allBits.count() then bit = allBits[index]
                        index = index + 1
                        if qrMaskBit(mask, r, c) then bit = 1 - bit
                        matrix[r][c] = bit
                    end if
                end for
            end for
            upward = not upward
            col = col - 2
        end while
        qrFormat(matrix, mask, SIZE)
        penalty = qrPenalty(matrix, SIZE)
        if best = invalid or penalty < bestPenalty then
            best = matrix
            bestPenalty = penalty
        end if
    end for
    return best
end function

sub qrPushBits(bits as Object, value as Integer, count as Integer)
    for i = count - 1 to 0 step -1
        bits.push((value >> i) and 1)
    end for
end sub

function qrMul(a as Integer, b as Integer, gfExp as Object, gfLog as Object) as Integer
    if a = 0 or b = 0 then return 0
    return gfExp[gfLog[a] + gfLog[b]]
end function

function qrEmpty(size as Integer, value as Integer) as Object
    rows = []
    for r = 0 to size - 1
        row = []
        for c = 0 to size - 1
            row.push(value)
        end for
        rows.push(row)
    end for
    return rows
end function

sub qrFinder(matrix as Object, r0 as Integer, c0 as Integer, size as Integer)
    for r = -1 to 7
        for c = -1 to 7
            rr = r0 + r
            cc = c0 + c
            if rr >= 0 and rr < size and cc >= 0 and cc < size then
                isOn = false
                if r >= 0 and r <= 6 and (c = 0 or c = 6) then isOn = true
                if c >= 0 and c <= 6 and (r = 0 or r = 6) then isOn = true
                if r >= 2 and r <= 4 and c >= 2 and c <= 4 then isOn = true
                if isOn then matrix[rr][cc] = 1 else matrix[rr][cc] = 0
            end if
        end for
    end for
end sub

function qrMaskBit(mask as Integer, r as Integer, c as Integer) as Boolean
    if mask = 0 then return (r + c) mod 2 = 0
    if mask = 1 then return r mod 2 = 0
    if mask = 2 then return c mod 3 = 0
    if mask = 3 then return (r + c) mod 3 = 0
    if mask = 4 then return (int(r / 2) + int(c / 3)) mod 2 = 0
    if mask = 5 then return (r * c) mod 2 + (r * c) mod 3 = 0
    if mask = 6 then return ((r * c) mod 2 + (r * c) mod 3) mod 2 = 0
    return ((r + c) mod 2 + (r * c) mod 3) mod 2 = 0
end function

sub qrFormat(matrix as Object, mask as Integer, size as Integer)
    ' Correcao L = 01
    formatValue = (1 << 3) or mask
    v = formatValue << 10
    for i = 14 to 10 step -1
        if (v and (1 << i)) <> 0 then v = qrXor(v, &h537 << (i - 10))
    end for
    fbits = qrXor((formatValue << 10) or v, &h5412)
    pos1 = [[8, 0], [8, 1], [8, 2], [8, 3], [8, 4], [8, 5], [8, 7], [8, 8], [7, 8], [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8]]
    pos2 = [[size - 1, 8], [size - 2, 8], [size - 3, 8], [size - 4, 8], [size - 5, 8], [size - 6, 8], [size - 7, 8], [8, size - 8], [8, size - 7], [8, size - 6], [8, size - 5], [8, size - 4], [8, size - 3], [8, size - 2], [8, size - 1]]
    for i = 0 to 14
        bit = (fbits >> (14 - i)) and 1
        matrix[pos1[i][0]][pos1[i][1]] = bit
        matrix[pos2[i][0]][pos2[i][1]] = bit
    end for
end sub

function qrPenalty(matrix as Object, size as Integer) as Integer
    penalty = 0
    for a = 0 to size - 1
        runRow = 1
        runCol = 1
        for b = 1 to size - 1
            if matrix[a][b] = matrix[a][b - 1] then
                runRow = runRow + 1
            else
                if runRow >= 5 then penalty = penalty + runRow - 2
                runRow = 1
            end if
            if matrix[b][a] = matrix[b - 1][a] then
                runCol = runCol + 1
            else
                if runCol >= 5 then penalty = penalty + runCol - 2
                runCol = 1
            end if
        end for
        if runRow >= 5 then penalty = penalty + runRow - 2
        if runCol >= 5 then penalty = penalty + runCol - 2
    end for
    return penalty
end function
