/*
A KBase module: AssemblyRAST
This modules run assemblers supported in the AssemblyRAST service.
*/

module AssemblyRAST {

    /*
        Run individual assemblers supported by AssemblyRAST.

        workspace_name - the name of the workspace for input/output
        read_library_name - the name of the PE read library (SE library support in the future)
        output_contig_set_name - the name of the output contigset

        extra_params - assembler specific parameters
        min_contig_length - minimum length of contigs to output, default 200

        @optional min_contig_len
        @optional extra_params
    */
    typedef structure {
        string workspace_name;
        list<string> read_library_names;
        list<string> read_library_refs;
        string output_contigset_name;

        int min_contig_len;
        list<string> extra_params;
    } AssemblyParams;

    typedef structure {
        string report_name;
        string report_ref;
    } AssemblyOutput;

    funcdef run_kiki(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_velvet(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_miniasm(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_spades(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_idba(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_megahit(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_ray(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_masurca(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_a5(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;

    funcdef run_a6(AssemblyParams params) returns (AssemblyOutput output)
        authentication required;


    /*
        Call AssemblyRAST.

        workspace_name - the name of the workspace for input/output
        read_library_name - the name of the PE read library (SE library support in the future)
        output_contig_set_name - the name of the output contigset

        extra_params - assembler specific parameters
        min_contig_length - minimum length of contigs to output, default 200

        @optional recipe
        @optional assembler
        @optional pipeline
        @optional min_contig_len
    */
    typedef structure {
        string workspace_name;
        list<string> read_library_names;
        string output_contigset_name;
        string recipe;
        string assembler;
        string pipeline;
        int min_contig_len;
    } ArastParams;

    funcdef run_arast(ArastParams params) returns (AssemblyOutput output)
        authentication required;

};
