
package us.kbase.assemblyrast;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: ArastParams</p>
 * <pre>
 * Call AssemblyRAST.
 * workspace_name - the name of the workspace for input/output
 * read_library_name - the name of the PE read library (SE library support in the future)
 * output_contig_set_name - the name of the output contigset
 * extra_params - assembler specific parameters
 * min_contig_length - minimum length of contigs to output, default 200
 * @optional recipe
 * @optional assembler
 * @optional pipeline
 * @optional min_contig_len
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace_name",
    "read_library_names",
    "output_contigset_name",
    "recipe",
    "assembler",
    "pipeline",
    "min_contig_len"
})
public class ArastParams {

    @JsonProperty("workspace_name")
    private java.lang.String workspaceName;
    @JsonProperty("read_library_names")
    private List<String> readLibraryNames;
    @JsonProperty("output_contigset_name")
    private java.lang.String outputContigsetName;
    @JsonProperty("recipe")
    private java.lang.String recipe;
    @JsonProperty("assembler")
    private java.lang.String assembler;
    @JsonProperty("pipeline")
    private java.lang.String pipeline;
    @JsonProperty("min_contig_len")
    private Long minContigLen;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("workspace_name")
    public java.lang.String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(java.lang.String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public ArastParams withWorkspaceName(java.lang.String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("read_library_names")
    public List<String> getReadLibraryNames() {
        return readLibraryNames;
    }

    @JsonProperty("read_library_names")
    public void setReadLibraryNames(List<String> readLibraryNames) {
        this.readLibraryNames = readLibraryNames;
    }

    public ArastParams withReadLibraryNames(List<String> readLibraryNames) {
        this.readLibraryNames = readLibraryNames;
        return this;
    }

    @JsonProperty("output_contigset_name")
    public java.lang.String getOutputContigsetName() {
        return outputContigsetName;
    }

    @JsonProperty("output_contigset_name")
    public void setOutputContigsetName(java.lang.String outputContigsetName) {
        this.outputContigsetName = outputContigsetName;
    }

    public ArastParams withOutputContigsetName(java.lang.String outputContigsetName) {
        this.outputContigsetName = outputContigsetName;
        return this;
    }

    @JsonProperty("recipe")
    public java.lang.String getRecipe() {
        return recipe;
    }

    @JsonProperty("recipe")
    public void setRecipe(java.lang.String recipe) {
        this.recipe = recipe;
    }

    public ArastParams withRecipe(java.lang.String recipe) {
        this.recipe = recipe;
        return this;
    }

    @JsonProperty("assembler")
    public java.lang.String getAssembler() {
        return assembler;
    }

    @JsonProperty("assembler")
    public void setAssembler(java.lang.String assembler) {
        this.assembler = assembler;
    }

    public ArastParams withAssembler(java.lang.String assembler) {
        this.assembler = assembler;
        return this;
    }

    @JsonProperty("pipeline")
    public java.lang.String getPipeline() {
        return pipeline;
    }

    @JsonProperty("pipeline")
    public void setPipeline(java.lang.String pipeline) {
        this.pipeline = pipeline;
    }

    public ArastParams withPipeline(java.lang.String pipeline) {
        this.pipeline = pipeline;
        return this;
    }

    @JsonProperty("min_contig_len")
    public Long getMinContigLen() {
        return minContigLen;
    }

    @JsonProperty("min_contig_len")
    public void setMinContigLen(Long minContigLen) {
        this.minContigLen = minContigLen;
    }

    public ArastParams withMinContigLen(Long minContigLen) {
        this.minContigLen = minContigLen;
        return this;
    }

    @JsonAnyGetter
    public Map<java.lang.String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(java.lang.String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public java.lang.String toString() {
        return ((((((((((((((((("ArastParams"+" [workspaceName=")+ workspaceName)+", readLibraryNames=")+ readLibraryNames)+", outputContigsetName=")+ outputContigsetName)+", recipe=")+ recipe)+", assembler=")+ assembler)+", pipeline=")+ pipeline)+", minContigLen=")+ minContigLen)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
