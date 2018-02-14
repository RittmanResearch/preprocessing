from shutil import copy
from os import path, chmod, system
from sys import argv
from itertools import repeat

FSLDIR="/applications/fsl/fsl-5.0.10/bin"

# define infiles and outfiles
fScan = argv[1] # functional scan
mask1 = argv[2] # 
#mask2 = argv[3]
x = argv[3]
ind = "ind"+str(x)+'.nii.gz'
pf = "parcelMean.txt"
tf = "tempScript.sh"
numCols=None

parcel = "/home/tr332/fmri_spt_wav/templates/parcel_temps/parcel_"+x+".nii"
outfile = fScan.replace(".nii.gz", x+"_ts.txt")

# copy parcel file locally
copy(parcel, path.basename(parcel))
parcel = path.basename(parcel)

# open outfile
f = open(outfile, "w")
f.close()

l = []
# mask parcel file by input mask
l.append(' '.join([path.join(FSLDIR, "fslchfiletype"), "NIFTI_GZ", parcel]))
parcel = parcel+'.gz'

l.append(' '.join([path.join(FSLDIR, "fslmaths"), parcel, "-mas", mask1, parcel]))
t = open(tf,"w")
t.writelines('\n'.join(l))
t.close()
chmod(tf, 0755)
system(tf)

for i in range(1, int(x)+1):
	l = []
	# extract parcel and binarise
	l.append(' '.join([path.join(FSLDIR, "fslmaths"), parcel, "-sub", str(i), ind]))
	l.append(' '.join([path.join(FSLDIR, "fslmaths"), ind, "-mul", ind, "-bin", "-mul", "-1", "-add", "1", ind]))
	
	# check size of parcel
	l.append('\n'.join(["d1=`"+path.join(FSLDIR, "fslval")+ " "+parcel+" dim1`","d2=`"+path.join(FSLDIR, "fslval")+ " "+parcel+" dim2`","d3=`"+path.join(FSLDIR, "fslval")+ " "+parcel+" dim3`"]))
	
	# write dimensions to file
	for val in [str(v) for v in [1,2,3]]:
		if val == "1":
			arrows=">"
		else:
			arrows=">>"
		l.append(' '.join(["echo","$d" +val, arrows, pf]))

	l.append(' '.join(["meanInd=`"+path.join(FSLDIR,"fslstats"),ind,"-m`"]))
	l.append(' '.join(["echo","$meanInd", ">>", pf]))

	t = open(tf,"w")
	t.writelines('\n'.join(l))
	t.close()
	chmod(tf, 0755)
	system(tf)
	
	vals = [float(v.strip('\n')) for v in open(pf).readlines()]
	size = 1
	for v in vals:
		size = size * v
	
	if size > 10:
#		print "Parcel number is approximately " + str(size) + ". Continuing to extract timeline."
		sl = []
		sl.append(' '.join(["line=`"+path.join(FSLDIR,"fslmeants"), "-i", fScan, "-m", ind, "--transpose`"]))
		sl.append(' '.join(["echo $line", ">>", outfile]))
		sl.append(' '.join(["rm", "-f", "$ind"]))
		t = open(tf,"w")
		t.writelines('\n'.join(sl)+'\n')
		t.close()
		
		system(tf)
				
	else:
		if not numCols:
			try:
				f = open(outfile,"r")
				line = f.readlines()[0]
				numCols = len(line.split())
			except:
				numCols = 145
			
#		print "Parcel number is approximately " + str(size) + ". Writing NAs to timeline file."
		f = open(outfile,"a")		
		NAline = repeat("NA", numCols)
		f.writelines(' '.join([ v for v in NAline ])+'\n')
		f.close()
	

