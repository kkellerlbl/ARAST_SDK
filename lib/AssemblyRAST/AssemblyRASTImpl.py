# -*- coding: utf-8 -*-
#BEGIN_HEADER
import os
import sys
import shutil
import hashlib
import subprocess
import traceback
import uuid
import logging
import pprint
import json
import tempfile
import re
from datetime import datetime
from AssemblyUtil.AssemblyUtilClient import AssemblyUtil
from pprint import pprint, pformat
from collections import Iterable

import numpy as np

from Bio import SeqIO

from biokbase.workspace.client import Workspace as workspaceService


# logging.basicConfig(format="[%(asctime)s %(levelname)s %(name)s] %(message)s", level=logging.DEBUG)
logger = logging.getLogger(__name__)

#END_HEADER


class AssemblyRAST:
    '''
    Module Name:
    AssemblyRAST

    Module Description:
    A KBase module: AssemblyRAST
This modules run assemblers supported in the AssemblyRAST service.
    '''

    ######## WARNING FOR GEVENT USERS ####### noqa
    # Since asynchronous IO can lead to methods - even the same method -
    # interrupting each other, you must be *very* careful when using global
    # state. A method could easily clobber the state set by another while
    # the latter method is running.
    ######################################### noqa
    VERSION = "0.0.4"
    GIT_URL = "git@github.com:scanon/ARAST_SDK.git"
    GIT_COMMIT_HASH = "9212af592b71ee2df38562378489b0dedee0bf1a"

    #BEGIN_CLASS_HEADER
    workspaceURL = None

    # target is a list for collecting log messages
    def log(self, target, message):
        # we should do something better here...
        if target is not None:
            target.append(message)
        print(message)
        sys.stdout.flush()

    def create_temp_json(self, attrs):
        f = tempfile.NamedTemporaryFile(delete=False)
        outjson = f.name
        f.write(json.dumps(attrs))
        f.close()
        return outjson

    # combine multiple read library objects into a kbase_assembly_input
    def combine_read_libs(self, libs):
        pe_libs = []
        se_libs = []
        refs = []
        for libobj in libs:
            data = libobj['data']
            info = libobj['info']
            #print(json.dumps(data))
            #print(json.dumps(info))
            type_name = info[2].split('.')[1].split('-')[0]
            lib = dict()
            if type_name == 'PairedEndLibrary':
                if 'lib1' in data:
                    lib['handle_1'] = data['lib1']['file']
                    if 'file_name' not in lib['handle_1']:
                        lib['handle_1']['file_name']='lib1.fq'
                elif 'handle_1' in data:
                    lib['handle_1'] = data['handle_1']
                    if 'file_name' not in lib['handle_1']:
                        lib['handle_1']['file_name']='lib1.fq'
                if 'lib2' in data:
                    lib['handle_2'] = data['lib2']['file']
                    if 'file_name' not in lib['handle_2']:
                        lib['handle_2']['file_name']='lib2.fq'
                elif 'handle_2' in data:
                    lib['handle_2'] = data['handle_2']
                    if 'file_name' not in lib['handle_2']:
                        lib['handle_2']['file_name']='lib2.fq'
                if 'interleaved' in data:
                    lib['interleaved'] = data['interleaved']
                    if isinstance(lib['interleaved'], Iterable) and 'file_name' not in lib['interleaved']:
                        lib['interleaved']['file_name']='reads.fq'
                pe_libs.append(lib)
            elif type_name == 'SingleEndLibrary':
                if 'lib' in data:
                    lib['handle'] = data['lib']['file']
                elif 'handle' in data:
                    lib['handle'] = data['handle']
                if 'file_name' not in lib['handle']:
                    lib['handle']['file_name']='reads.fq'
                se_libs.append(lib)

        assembly_input = { 'paired_end_libs': pe_libs,
                           'single_end_libs': se_libs,
                           'references': refs }
        logger.debug('kbase_assembly_input = {}'.format(json.dumps(assembly_input)))
        return assembly_input

    # template
    def arast_run(self, ctx, params, assembler, server='http://localhost:8000/'):
        output = None

        console = []
        self.log(console,'Running run_{} with params='.format(assembler))
        self.log(console, pformat(params))

        #### do some basic checks
        if 'workspace_name' not in params:
            raise ValueError('workspace_name parameter is required')
        if 'read_library_refs' not in params and 'read_library_names' not in params:
            raise ValueError('read_library_refs or read_library_names parameter is required')
        if 'read_library_refs' in params:
            if type(params['read_library_refs']) != list:
                raise ValueError('read_library_refs must be a list')
        if 'read_library_names' in params:
            if type(params['read_library_names']) != list:
                raise ValueError('read_library_names must be a list')
        if 'output_contigset_name' not in params:
            raise ValueError('output_contigset_name parameter is required')
        min_contig_len = params.get('min_contig_len') or 300

        token = ctx['token']

        os.environ["KB_AUTH_TOKEN"] = token
        os.environ["ARAST_URL"] =  server

        ws = workspaceService(self.workspaceURL)
        ws_libs = []
        if 'read_library_refs' in params:
            for lib_ref in params['read_library_refs']:
                ws_libs.append({'ref': lib_ref})
        if 'read_library_names' in params:
            for lib_name in params['read_library_names']:
                ws_libs.append({'ref': params['workspace_name'] + '/' + lib_name})
        if len(ws_libs)==0:
            raise ValueError('At least one read library must be provided in read_library_refs or read_library_names')
        libs = ws.get_objects2({'objects': ws_libs})['data']

        wsid = libs[0]['info'][6]

        kbase_assembly_input = self.combine_read_libs(libs)
        tmp_data = self.create_temp_json(kbase_assembly_input)

        mode = ''
        cmd = ['ar-run', '--data-json', tmp_data]
        if assembler:
            cmd = cmd + ['-a', assembler]
            mode = 'assembler: ' + assembler
        elif 'pipeline' in params and params['pipeline']:
            cmd = cmd + ['-p', params['pipeline']]
            mode = 'assembly pipeline: ' + params['pipeline']
        else:
            cmd = cmd + ['-r', params.get('recipe', 'auto')]
            mode = 'assembly recipe: ' + params['recipe']

        logger.info('Start {}'.format(mode))
        logger.debug('CMD: {}'.format(' '.join(cmd)))

        p = subprocess.Popen(cmd,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, shell=False)

        out, err = p.communicate()
        logger.debug(out)

        if p.returncode != 0:
            raise ValueError('Error running ar_run, return code: {}\n'.format(p.returncode))

        job_id = None
        match = re.search('(\d+)', out)
        if match:
            job_id = match.group(1)
        else:
            raise ValueError('No integer job ID found: {}\n'.format(out))

        timestamp = int((datetime.utcnow() - datetime.utcfromtimestamp(0)).total_seconds()*1000)
        output_dir = os.path.join(self.scratch, 'output.'+str(timestamp))
        output_contigs = os.path.join(output_dir, 'contigs.fa')
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        cmd = ['ar-get', '-j', job_id, '-w', '-l']
        logger.debug('CMD: {}'.format(' '.join(cmd)))
        ar_log = subprocess.check_output(cmd)

        self.log(console, ar_log)

        cmdstr = 'ar-get -j {} -w -p | ar-filter -l {} > {}'.format(job_id, min_contig_len, output_contigs)
        logger.debug('CMD: {}'.format(cmdstr))
        subprocess.check_call(cmdstr, shell=True)

        cmd = ['ar-get', '-j', job_id, '-w', '-r']
        logger.debug('CMD: {}'.format(' '.join(cmd)))
        ar_report = subprocess.check_output(cmd)

        self.log(console, "\nDONE\n")

        client = AssemblyUtil(self.callback_url)
        assembly_ref = client.save_assembly_from_fasta({
                        'file':{'path':output_contigs},
                        'workspace_name':params['workspace_name'],
                        'assembly_name':params['output_contigset_name']
               	})
        
        lengths = []
        for seq_record in SeqIO.parse(output_contigs, 'fasta'):
            lengths.append(len(seq_record.seq))

        provenance = [{}]
        if 'provenance' in ctx:
            provenance = ctx['provenance']
        # add additional info to provenance here, in this case the input data object reference
        if 'read_library_names' in params:
            provenance[0]['input_ws_objects']=[params['workspace_name']+'/'+x for x in params['read_library_names']]
        elif 'read_library_refs' in params:
            provenance[0]['input_ws_objects']=[x for x in params['read_library_refs']]


        os.remove(tmp_data)
        #shutil.rmtree(output_dir)

        # create a Report
        report = ''
        report += '============= Raw Contigs ============\n' + ar_report + '\n'

        report += '========== Filtered Contigs ==========\n'
        report += 'ContigSet saved to: '+params['workspace_name']+'/'+params['output_contigset_name']+'\n'
        report += 'Assembled into '+str(len(lengths)) + ' contigs.\n'
        report += 'Average Length: '+str(sum(lengths)/float(len(lengths))) + ' bp.\n'

        # compute a simple contig length distribution
        bins = 10
        counts, edges = np.histogram(lengths, bins)
        report += 'Contig Length Distribution (# of contigs -- min to max basepairs):\n'
        for c in range(bins):
            report += '   '+str(counts[c]) + '\t--\t' + str(edges[c]) + ' to ' + str(edges[c+1]) + ' bp\n'

        print report

        reportObj = {
            'objects_created':[{'ref':params['workspace_name']+'/'+params['output_contigset_name'], 'description':'Assembled contigs'}],
            'text_message': report
        }

        reportName = '{}.report.{}'.format(assembler, job_id)
        report_obj_info = ws.save_objects({
                'id': wsid,
                'objects': [
                    {
                        'type': 'KBaseReport.Report',
                        'data': reportObj,
                        'name': reportName,
                        'meta': {},
                        'hidden': 1,
                        'provenance': provenance
                    }
                ]
            })[0]

        output = { 'report_name': reportName, 'report_ref': str(report_obj_info[6]) + '/' + str(report_obj_info[0]) + '/' + str(report_obj_info[4]) }

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method filter_contigs return value ' +
                             'returnVal is not type dict as required.')
        # return the results
        return output

    #END_CLASS_HEADER

    # config contains contents of config file in a hash or None if it couldn't
    # be found
    def __init__(self, config):
        #BEGIN_CONSTRUCTOR
        self.workspaceURL = config['workspace-url']
        self.scratch = os.path.abspath(config['scratch'])
        self.callback_url = os.environ['SDK_CALLBACK_URL']
        if not os.path.exists(self.scratch):
            os.makedirs(self.scratch)
        #END_CONSTRUCTOR
        pass


    def run_kiki(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_kiki
        output = self.arast_run(ctx, params, "kiki")
        #END run_kiki

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_kiki return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_velvet(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_velvet
        output = self.arast_run(ctx, params, "velvet")
        #END run_velvet

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_velvet return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_miniasm(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_miniasm
        output = self.arast_run(ctx, params, "miniasm")
        #END run_miniasm

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_miniasm return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_spades(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_spades
        output = self.arast_run(ctx, params, "spades")
        #END run_spades

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_spades return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_idba(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_idba
        output = self.arast_run(ctx, params, "idba")
        #END run_idba

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_idba return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_megahit(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_megahit
        output = self.arast_run(ctx, params, "megahit")
        #END run_megahit

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_megahit return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_ray(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_ray
        output = self.arast_run(ctx, params, "ray")
        #END run_ray

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_ray return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_masurca(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_masurca
        output = self.arast_run(ctx, params, "masurca")
        #END run_masurca

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_masurca return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_a5(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_a5
        output = self.arast_run(ctx, params, "a5")
        #END run_a5

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_a5 return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_a6(self, ctx, params):
        """
        :param params: instance of type "AssemblyParams" (Run individual
           assemblers supported by AssemblyRAST. workspace_name - the name of
           the workspace for input/output read_library_name - the name of the
           PE read library (SE library support in the future)
           output_contig_set_name - the name of the output contigset
           extra_params - assembler specific parameters min_contig_length -
           minimum length of contigs to output, default 200 @optional
           min_contig_len @optional extra_params) -> structure: parameter
           "workspace_name" of String, parameter "read_library_names" of list
           of String, parameter "read_library_refs" of list of String,
           parameter "output_contigset_name" of String, parameter
           "min_contig_len" of Long, parameter "extra_params" of list of
           String
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_a6
        output = self.arast_run(ctx, params, "a6")
        #END run_a6

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_a6 return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]

    def run_arast(self, ctx, params):
        """
        :param params: instance of type "ArastParams" (Call AssemblyRAST.
           workspace_name - the name of the workspace for input/output
           read_library_name - the name of the PE read library (SE library
           support in the future) output_contig_set_name - the name of the
           output contigset extra_params - assembler specific parameters
           min_contig_length - minimum length of contigs to output, default
           200 @optional recipe @optional assembler @optional pipeline
           @optional min_contig_len) -> structure: parameter "workspace_name"
           of String, parameter "read_library_names" of list of String,
           parameter "read_library_refs" of list of String, parameter
           "output_contigset_name" of String, parameter "recipe" of String,
           parameter "assembler" of String, parameter "pipeline" of String,
           parameter "min_contig_len" of Long
        :returns: instance of type "AssemblyOutput" -> structure: parameter
           "report_name" of String, parameter "report_ref" of String
        """
        # ctx is the context object
        # return variables are: output
        #BEGIN run_arast
        output = self.arast_run(ctx, params, params.get('assembler', ""))
        #END run_arast

        # At some point might do deeper type checking...
        if not isinstance(output, dict):
            raise ValueError('Method run_arast return value ' +
                             'output is not type dict as required.')
        # return the results
        return [output]
    def status(self, ctx):
        #BEGIN_STATUS
        returnVal = {'state': "OK",
                     'message': "",
                     'version': self.VERSION,
                     'git_url': self.GIT_URL,
                     'git_commit_hash': self.GIT_COMMIT_HASH}
        #END_STATUS
        return [returnVal]
