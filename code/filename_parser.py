'''
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Convert a long filename into a Stata do-file call with parameters.
'''
import sys
import os

filename = sys.argv[1]

dir, name = os.path.split(filename)
root, ext = os.path.splitext(name)

def makefile_encode(string):
	return string.replace("=", "~").replace(" ", "+")
def makefile_decode(string):
	return string.replace("~", "=").replace("+", " ")

output = "stata-se -b wrap "+dir+"/"+makefile_decode(root)
for part in sys.argv[2:]:
	output += " "+part
print output
os.system(output)