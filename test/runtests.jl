using LinearAlgebra, SnpArrays, SparseArrays, Test

const EUR = SnpArray(SnpArrays.datadir("EUR_subset.bed")) # no missing genotypes
const mouse = SnpArray(SnpArrays.datadir("mouse.bed")) # has missing genotypes

@testset "size" begin
@test size(EUR) == (379, 54051)
@test size(EUR, 1) == 379
@test size(EUR, 2) == 54051
@test size(mouse) == (1940, 10150)
@test size(mouse, 3) == 1
@test_throws ErrorException size(mouse, 0)
@test length(mouse) == 1940 * 10150
@test eltype(mouse) == UInt8
end

@testset "counts" begin
cc = counts(EUR, dims=1)
@test counts(EUR) == sum(cc, dims=2)
@test size(cc) == (4, size(EUR, 2))
@test view(cc, :, 1) == [2, 0, 70, 307]
@test all(sum(cc, dims = 1) .== size(EUR, 1))
@test all(iszero, view(cc, 2, :))
rc = counts(EUR, dims=2)
@test size(rc) == (4, size(EUR, 1))
@test view(rc, :, 1) == [2997, 0, 13143, 37911]
@test all(sum(rc, dims = 1) .== size(EUR, 2))
@test all(iszero, view(rc, 2, :))
@test_throws ArgumentError counts(EUR, dims=3)
end

@testset "means" begin
# ADDITIVE_MODEL
cmns = mean(EUR, dims = 1)
@test size(cmns) == (1, size(EUR, 2))
@test cmns[1] ≈ 1.804749340369393
@test mean(cmns) ≈ mean(EUR)
@test minimum(cmns) ≈ 1.0
@test maximum(cmns) ≈ 1.9788918205804749
rmns = mean(EUR, dims = 2)
@test size(rmns) == (size(EUR, 1), 1)
@test rmns[1] ≈ 1.6459454959205195
@test mean(rmns) ≈ mean(EUR)
rmnextrma = extrema(rmns)
@test rmnextrma[1] ≈ 1.637749532848606
@test rmnextrma[2] ≈ 1.6627259440158368
@test_throws ArgumentError mean(EUR, dims=3)
# DOMINANT_MODEL
cmns = mean(EUR, dims = 1, model = DOMINANT_MODEL)
@test size(cmns) == (1, size(EUR, 2))
@test cmns[1] ≈ 0.9947229551451188
@test mean(cmns) ≈ mean(EUR, model = DOMINANT_MODEL)
@test minimum(cmns) ≈ 0.5989445910290238
@test maximum(cmns) ≈ 1.0
rmns = mean(EUR, dims = 2, model = DOMINANT_MODEL)
@test size(rmns) == (size(EUR, 1), 1)
@test rmns[1] ≈ 0.9445523672087472
@test mean(rmns) ≈ mean(EUR, model = DOMINANT_MODEL)
rmnextrma = extrema(rmns)
@test rmnextrma[1] ≈ 0.9325266877578583
@test rmnextrma[2] ≈ 0.9530073449149877
@test_throws ArgumentError mean(EUR, dims=3, model=DOMINANT_MODEL)
# RECESSIVE_MODEL
cmns = mean(EUR, dims = 1, model = RECESSIVE_MODEL)
@test size(cmns) == (1, size(EUR, 2))
@test cmns[1] ≈ 0.8100263852242744
@test mean(cmns) ≈ mean(EUR, model = RECESSIVE_MODEL)
@test minimum(cmns) ≈ 0.0
@test maximum(cmns) ≈ 0.9868073878627969
rmns = mean(EUR, dims = 2, model = RECESSIVE_MODEL)
@test size(rmns) == (size(EUR, 1), 1)
@test rmns[1] ≈ 0.7013931287117722
@test mean(rmns) ≈ mean(EUR, model = RECESSIVE_MODEL)
rmnextrma = extrema(rmns)
@test rmnextrma[1] ≈ 0.6932341677304767
@test rmnextrma[2] ≈ 0.7191171301178516
@test_throws ArgumentError mean(EUR, dims=3, model=RECESSIVE_MODEL)
end

@testset "var/std" begin
cvars = var(EUR, dims = 1)
@test size(cvars) == (1, size(EUR, 2))
@test cvars[1] ≈ 0.16812553224162724
@test iszero(minimum(cvars))
@test maximum(cvars) ≈ 0.8705727966941688
@test std(EUR, dims = 1) ≈ sqrt.(cvars)
rvars = var(EUR, dims = 2)
@test size(rvars) == (size(EUR, 1), 1)
@test rvars[1] ≈ 0.33960146078503206
@test minimum(rvars) ≈ 0.31972707244268267
@test maximum(rvars) ≈ 0.365901927927013
@test std(EUR, dims = 2) ≈ sqrt.(rvars)
end

@testset "missingpos" begin
mp = missingpos(mouse)
cc = counts(mouse, dims=1)
@test isa(mp, SparseMatrixCSC)
@test sum(mp, dims = 1) == view(cc, 2:2, :)
@test sum(mp, dims = 2) == view(counts(mouse, dims=2), 2:2, :)'
end

@testset "create bed" begin
tmpbf = SnpArray("tmp.bed", 5, 3)
@test isfile("tmp.bed")
@test all(tmpbf .== 0x00)
fill!(tmpbf, 0x02)
tmpbf2 = SnpArray("tmp.bed", 5)
@test all(tmpbf2 .== 0x02)
rm("tmp.bed")
tmpbf = SnpArray("tmp.bed", SnpArray(undef, 5, 3))
fill!(tmpbf, 0x01)
@test all(tmpbf .== 0x01)
rm("tmp.bed")
end

@testset "convert" begin
# check convert coding
tmpbf = SnpArray(undef, 4, 1)
tmpbf[1] = 0x00
tmpbf[2] = 0x01
tmpbf[3] = 0x02
tmpbf[4] = 0x03
# additive model
v = convert(Matrix{Float64}, tmpbf, model=ADDITIVE_MODEL)
@test all([v[1], v[3], v[4]] .== [0.0, 1.0, 2.0])
@test isnan(v[2])
# dominant model
v = convert(Matrix{Float64}, tmpbf, model=DOMINANT_MODEL)
@test all([v[1], v[3], v[4]] .== [0.0, 1.0, 1.0])
@test isnan(v[2])
# recessive model
v = convert(Matrix{Float64}, tmpbf, model=RECESSIVE_MODEL)
@test all([v[1], v[3], v[4]] .== [0.0, 0.0, 1.0])
@test isnan(v[2])
# mouse test data
cmns = mean(mouse, dims = 1)
cvrs = var(mouse, dims = 1)
cstd = std(mouse, dims = 1)
v = convert(Vector{Float64}, @view(mouse[:, 1]))
@test isnan(mean(v))
@test mean(filter(!isnan, v)) ≈ cmns[1]
@test isnan(var(v))
@test var(filter(!isnan, v)) ≈ cvrs[1]
@test isnan(std(v))
@test std(filter(!isnan, v)) ≈ cstd[1]
end

@testset "maf" begin
cc = counts(mouse, dims=1)
@test all(0 .≤ maf(mouse) .≤ 0.5)
@test all(minorallele(mouse) .== (cc[1, :] .> cc[4, :]))
cc = counts(EUR, dims=1)
@test all(0 .≤ maf(EUR) .≤ 0.5)
@test all(minorallele(EUR) .== (cc[1, :] .> cc[4, :]))
end

@testset "grm" begin
Φgrm = grm(EUR, method=:GRM)
@test size(Φgrm) == (size(EUR, 1), size(EUR, 1))
@test issymmetric(Φgrm)
@test eigmin(Φgrm) > -1e-8
Φmom = grm(EUR, method=:MoM)
@test size(Φmom) == (size(EUR, 1), size(EUR, 1))
@test issymmetric(Φmom)
Φrbs = grm(EUR, method=:Robust)
@test size(Φrbs) == (size(EUR, 1), size(EUR, 1))
@test issymmetric(Φrbs)
@test eigmin(Φrbs) > -1e-8
end

@testset "filter" begin
rowmask, colmask =  SnpArrays.filter(mouse, 0.99, 0.99)
SnpArrays.filter(SnpArrays.datadir("mouse"), rowmask, colmask; des="tmp")
tmpbf = SnpArray("tmp.bed")
@test size(tmpbf) == (1907, 9997)
@test all(missingrate(tmpbf, 1) .≤ 0.01)
@test all(missingrate(tmpbf, 2) .≤ 0.01)
rm("tmp.bed")
rm("tmp.bim")
rm("tmp.fam")
end

@testset "lin. alg." begin
for t in [Float32, Float64]
    v1 = randn(t, size(EUR, 1))
    v2 = randn(t, size(EUR, 2))
    for model in [ADDITIVE_MODEL, DOMINANT_MODEL, RECESSIVE_MODEL]
        @test norm(SnpBitMatrix{t}(EUR, model=model) * v2 -
            convert(Matrix{t}, EUR, model=model) * v2) / 
            norm(convert(Matrix{t}, EUR, model=model) * v2)  < 1e-4
        @test norm(SnpBitMatrix{t}(EUR, center=true, model=model) * v2 - 
            convert(Matrix{t}, EUR, center=true, model=model) * v2) /
            norm(convert(Matrix{t}, EUR, center=true, model=model) * v2) < 1e-4
        @test norm(SnpBitMatrix{t}(EUR, scale=true, model=model) * v2 - 
            convert(Matrix{t}, EUR, scale=true, model=model) * v2) /
            norm(convert(Matrix{t}, EUR, scale=true, model=model) * v2) < 1e-4
        @test norm(SnpBitMatrix{t}(EUR, center=true, scale=true, model=model) * v2 - 
            convert(Matrix{t}, EUR, center=true, scale=true, model=model) * v2) /
            norm(convert(Matrix{t}, EUR, center=true, scale=true, model=model) * v2) < 1e-4
        @test norm(transpose(SnpBitMatrix{t}(EUR, model=model)) * v1 - 
            transpose(convert(Matrix{t}, EUR, model=model)) * v1) /
            norm(transpose(convert(Matrix{t}, EUR, model=model)) * v1) < 1e-4
        @test norm(transpose(SnpBitMatrix{t}(EUR, center=true, model=model)) * v1 - 
            transpose(convert(Matrix{t}, EUR, center=true, model=model)) * v1) /
            norm(transpose(convert(Matrix{t}, EUR, center=true, model=model)) * v1) < 1e-4
        @test norm(transpose(SnpBitMatrix{t}(EUR, scale=true, model=model)) * v1 - 
            transpose(convert(Matrix{t}, EUR, scale=true, model=model)) * v1) /
            norm(transpose(convert(Matrix{t}, EUR, scale=true, model=model)) * v1) < 1e-4
        @test norm(transpose(SnpBitMatrix{t}(EUR, center=true, scale=true, model=model)) * v1 - 
            transpose(convert(Matrix{t}, EUR, center=true, scale=true, model=model)) * v1) /
            norm(transpose(convert(Matrix{t}, EUR, center=true, scale=true, model=model)) * v1) < 1e-4
    end
end
end

@testset "subarrays" begin
@test all(@view(EUR[1:2:10, 1:2:10]) .==
[[0x03 0x03 0x02 0x02 0x03];
[0x03 0x03 0x03 0x03 0x03];
[0x03 0x03 0x03 0x03 0x03];
[0x02 0x03 0x02 0x00 0x02];
[0x03 0x03 0x02 0x02 0x03]
])
@test all(convert(Matrix{Float64}, @view(EUR[1:2:10, 1:2:10])) .≈ 
[[2.0 2.0 1.0 1.0 2.0];
[2.0 2.0 2.0 2.0 2.0];
[2.0 2.0 2.0 2.0 2.0];
[1.0 2.0 1.0 0.0 1.0];
[2.0 2.0 1.0 1.0 2.0]
])

EURsub = @view EUR[1:2:100, 1:2:100]
EURsubbm = SnpBitMatrix{Float64}(EURsub, model=ADDITIVE_MODEL, center=true, scale=true) # BitMatrix from the SubArray 
EURsubfm = convert(Matrix{Float64}, EURsub, model=ADDITIVE_MODEL, center=true, scale=true) # Float64 Matrix from the SubArray

v1 = randn(size(EURsub, 1))
v2 = randn(size(EURsub, 2))

@test all(EURsubbm * v2 .≈ EURsubfm * v2)
@test all(EURsubbm' * v1 .≈ EURsubfm' * v1)
end

@testset "split-merge-readwrite" begin
EUR_data = SnpData(SnpArrays.datadir("EUR_subset"))

# filter
chr17 = SnpArrays.filter(SnpArrays.datadir("EUR_subset"); des="tmp.filter.chr17", f_snp = x -> x[:chromosome] == "17")
@test chr17.snps == 11041
@test chr17.people == 379
male = SnpArrays.filter(EUR_data; des="tmp.filter.male", f_person = x -> x[:sex] == "1")
@test male.snps == 54051
@test male.people == 178
chr17_male = SnpArrays.filter(EUR_data; des="tmp.filter.chr17.male", f_snp = x -> x[:chromosome] == "17", f_person = x -> x[:sex] == "1")
@test chr17_male.snps == 11041
@test chr17_male.people == 178
@test size(chr17_male.snparray) == (178, 11041)
# cleanup
for ft in ["bim", "fam", "bed"]
    isfile("tmp.filter.chr17." * ft) && rm("tmp.filter.chr17." * ft)
    isfile("tmp.filter.male." * ft) && rm("tmp.filter.male." * ft)
    isfile("tmp.filter.chr17.male." * ft) && rm("tmp.filter.chr17.male." * ft)
end


# split
splitted = SnpArrays.split_plink(SnpArrays.datadir("EUR_subset"); prefix="tmp.split.chr.")
piece = splitted["17"]
@test piece.people == 379
@test piece.snps == 11041
@test size(piece.person_info) == (379, 6)
@test size(piece.snp_info) == (11041, 6)
@test size(piece.snparray) == (379, 11041)
@test size(piece.snparray.columncounts) == (4, 11041)
@test piece.snparray.m == 379
@test size(piece.snparray.data) == (95, 11041)
splitted_bysex = SnpArrays.split_plink(EUR_data, :sex; prefix="tmp.split.sex.")
@test splitted_bysex["1"].people == 178
@test splitted_bysex["2"].people == 201


merged = SnpArrays.merge_plink("tmp.merged", splitted) # write_plink is included here
@test EUR_data.people == merged.people
@test EUR_data.snps == merged.snps
@test EUR_data.person_info == merged.person_info
@test EUR_data.snp_info == merged.snp_info # note: the ordering of merged data might be different on other dataset b/c sorted order of chromosomes

output = SnpData("tmp.merged")
@test EUR_data.people == output.people
@test EUR_data.snps == output.snps
@test EUR_data.person_info == output.person_info
@test EUR_data.snp_info == output.snp_info

# cleanup
isfile("tmp.merged.bim") && rm("tmp.merged.bim")
isfile("tmp.merged.fam") && rm("tmp.merged.fam")
isfile("tmp.merged.bed") && rm("tmp.merged.bed")

# merge from splitted files
merged_from_splitted_files = merge_plink("tmp.split.chr"; des = "tmp.merged")
@test EUR_data.people == merged_from_splitted_files.people
@test EUR_data.snps == merged_from_splitted_files.snps
@test EUR_data.person_info == merged_from_splitted_files.person_info
@test EUR_data.snp_info == merged_from_splitted_files.snp_info

# cleanup
isfile("tmp.merged.bim") && rm("tmp.merged.bim")
isfile("tmp.merged.fam") && rm("tmp.merged.fam")
isfile("tmp.merged.bed") && rm("tmp.merged.bed")

for k in keys(splitted)
    for ft in ["bim", "fam", "bed"]
        isfile("tmp.split.chr.$(k)." * ft) && rm("tmp.split.chr.$(k)." * ft)
    end
end  
for k in keys(splitted_bysex)
    for ft in ["bim", "fam", "bed"]
        isfile("tmp.split.sex.$(k)." * ft) && rm("tmp.split.sex.$(k)." * ft)
    end
end  
end

@testset "(de)compress" begin
for format in ["gz", "zlib", "zz"]
    # compress mouse Plink files
    compress_plink(SnpArrays.datadir("mouse"), format)
    @test isfile(SnpArrays.datadir("mouse.bed." * format))
    @test isfile(SnpArrays.datadir("mouse.fam." * format))
    @test isfile(SnpArrays.datadir("mouse.bim." * format))
    # read in compressed Plink files
    mouse_zip = SnpArray(SnpArrays.datadir("mouse.bed." * format))
    fill!(mouse.rowcounts, 0)
    fill!(mouse.columncounts, 0)
    @time begin
        SnpArrays._counts(mouse, 1)
        SnpArrays._counts(mouse, 2)
    end
    fill!(mouse_zip.rowcounts, 0)
    fill!(mouse_zip.columncounts, 0)
    @time begin
        SnpArrays._counts(mouse_zip, 1)
        SnpArrays._counts(mouse_zip, 2)
    end
    @test mouse.m == mouse_zip.m
    @test norm(mouse.rowcounts - mouse_zip.rowcounts) < 1e-8
    @test norm(mouse.columncounts - mouse_zip.columncounts) < 1e-8
    @test norm(mouse.data - mouse_zip.data) < 1e-8
    # Decompress Plink files
    decompress_plink(SnpArrays.datadir("mouse"), format, SnpArrays.datadir("mouse2"))
    @test stat(SnpArrays.datadir("mouse") * ".bed").size == 
    stat(SnpArrays.datadir("mouse2") * ".bed").size
    @test stat(SnpArrays.datadir("mouse") * ".fam").size == 
    stat(SnpArrays.datadir("mouse2") * ".fam").size
    @test stat(SnpArrays.datadir("mouse") * ".bim").size == 
    stat(SnpArrays.datadir("mouse2") * ".bim").size
    # clean up
    isfile(SnpArrays.datadir("mouse.bed." * format)) && rm(SnpArrays.datadir("mouse.bed." * format))
    isfile(SnpArrays.datadir("mouse.fam." * format)) && rm(SnpArrays.datadir("mouse.fam." * format))
    isfile(SnpArrays.datadir("mouse.bim." * format)) && rm(SnpArrays.datadir("mouse.bim." * format))
    isfile(SnpArrays.datadir("mouse2.bed")) && rm(SnpArrays.datadir("mouse2.bed"))
    isfile(SnpArrays.datadir("mouse2.fam")) && rm(SnpArrays.datadir("mouse2.fam"))
    isfile(SnpArrays.datadir("mouse2.bim")) && rm(SnpArrays.datadir("mouse2.bim"))
end
@test_throws ArgumentError SnpArray(SnpArrays.datadir("mouse.bed.zip"))
end
