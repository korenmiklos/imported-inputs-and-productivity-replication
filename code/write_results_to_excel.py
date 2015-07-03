'''
Replication code for "Imported Inputs and Productivity". Please cite as
	Halpern, Koren and Szeidl. 2015. "Imported Inputs and Productivity." American Economic Review.

Create a regression table from a set of statistics saved in .csv files.
'''

import glob
import csv
import StringIO
import re
import sys
from collections import OrderedDict

NAMES = OrderedDict(b_lnK='Capital',
	b_lnL='Labor',
	b_PlnM='Material',
	ahat1='Per-product import gain',
	shat1='Import share',
	B1='Efficiency of imports (A)',
	theta='Elasticity of substitution',
	Lambda='Curvature of G(n)',
	b_afterforeign='Foreign ownership',
	b_exporter='Exporter',
	b_importedbefore='Previous importer',
	b_demand_1='Industry sales',
	b_demand_2='Local demand growth',
	lagGn='Lagged G(n) in second stage',
	b_lagGn_1='Lagged G(n) in second stage, domestic',
	b_lagGn_2='Lagged G(n) in second stage, foreign',
	Nfirms='Number of observations',
	p_B1_EDF='P-value of test for A=1',
	b_lag_log_n1='Lag of ln(1+n)')

def verbose_name(name):
	# change variable name bc lambda is a reserved word
	if name=="lambda":
		name = "Lambda"
	if name in NAMES:
		return NAMES[name]
	else:
		return name

def numeric(text):
	try:
		return float(text)
	except:
		return None

class Estimate(object):
	def __init__(self, parameter_name, point_estimate, standard_error=None, lower=None, upper=None):
		self.parameter_name = parameter_name
		self.point_estimate = point_estimate
		self.standard_error = standard_error
		self.lower = lower
		self.upper = upper

	def render(self):
		if self.lower is not None:
			return '%0.3f [%0.3f, %0.3f]' % (self.point_estimate, self.lower, self.upper)
		if self.standard_error is not None:
			return '%0.3f (%0.3f)' % (self.point_estimate, self.standard_error)
		else:
			return '%0.3f' % self.point_estimate

class Specification(object):
	def __init__(self, name, estimates, notes=''):
		self.name = name
		self.estimates = estimates
		self.notes = notes

	def parameters(self):
		return [estimate.parameter_name for estimate in self.estimates]

	def render_as_list(self):
		return [estimate.render() for estimate in self.estimates]

	def render_parameter_estimate(self, parameter_name):
		if parameter_name in self.parameters():
			return self.render_as_list()[self.parameters().index(parameter_name)]
		else:
			return ''

class Table(object):
	def __init__(self, title, specifications, notes=''):
		self.title = title
		self.specifications = specifications
		self.notes = notes
		self.list_of_parameters = []
		for specification in self.specifications:
			for parameter_name in specification.parameters():
				if not parameter_name in self.list_of_parameters:
					self.list_of_parameters.append(parameter_name)

	def parameters(self):
		return self.list_of_parameters

	def row_number(self, parameter_name):
		return self.parameters().index(parameter_name)

	def render_as_list_of_lists(self):
		table = []
		for specification in self.specifications:
			column = ['']*len(self.parameters())
			for estimate in specification.estimates:
				column[self.row_number(estimate.parameter_name)] = estimate.render()
			table.append(column)
		return table

	def render_as_list_of_rows(self):
		rows = []
		rows.append([self.title])
		
		rows.append(['']+range(1,len(self.specifications)+1))
		rows.append(['Parameter']+[spec.name for spec in self.specifications])

		for parameter_name in self.parameters():
			rows.append([parameter_name]+[spec.render_parameter_estimate(parameter_name) for spec in self.specifications])

		rows.append([spec.notes for spec in self.specifications])

		rows.append([self.notes])

		return rows

	def render_as_csv(self):
		stream = StringIO.StringIO()
		output = csv.writer(stream)
		for row in self.render_as_list_of_rows():
			output.writerow(row)
		stream.seek(0)
		return stream.read()

def read_estimates(name):
	regex = re.compile("../doc/mapreduce/(.+?)_(.+)/estimates.csv")
	specifications = []
	for file_name in glob.glob('../doc/mapreduce/'+name+'_*/estimates.csv'):
		title = regex.search(file_name).groups()[1]
		reader = csv.DictReader(open(file_name,"r"))
		estimates = []
		for row in reader:
			if not row['estimate']=='': 
				estimates.append(Estimate(verbose_name(row['parameter']), numeric(row['estimate']), numeric(row['se'])))
		specifications.append(Specification(title.title(), estimates))
	return Table(name, specifications)

def test():
	b_lnK = Estimate(NAMES['b_lnK'], 0.02, 0.001)
	b_lnL = Estimate(NAMES['b_lnL'], 0.18, 0.007)
	theta = Estimate(NAMES['theta'], 4.22, lower=3.2, upper=5.2)

	baseline = Specification('Baseline', [b_lnK,b_lnL])
	with_theta = Specification('With theta', [b_lnK,b_lnL,theta])
	k_and_theta = Specification('With theta', [b_lnK,theta])
	table3 = Table('Production function estimates', [baseline, with_theta, k_and_theta])

	print with_theta.render_as_list()
	print table3.render_as_list_of_lists()
	print table3.render_as_list_of_rows()
	print table3.render_as_csv()

if __name__ == '__main__':
	table_name = sys.argv[1].split('-')[0]
	print read_estimates(table_name).render_as_csv()