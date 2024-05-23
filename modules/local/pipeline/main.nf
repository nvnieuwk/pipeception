import groovy.json.JsonBuilder

process PIPELINE {
    debug true
    scratch { "${workDir}/${pipeline}/${meta.id}" }
    // This will make sure that the work directory is the same (this makes sure that `-resume` works)

    input:
    tuple val(meta), path(inputs, stageAs:"../*")
    val(pipeline)
    val(options)
    val(paramsMap)

    output:
    tuple val(meta), path("../${outdir}")                   , emit: outdir, optional:true
    tuple val(meta), path("../.nextflow.log", hidden:true)  , emit: log
    tuple val(meta), path("../${workdir}")                  , emit: work, optional:true

    script:
    def output = paramsMap.get("outdir")
    def work = options.get("work-dir") ?: options.get("w")

    if(!output) { error("Please supply an output directory via the parameters (--outdir)")}
    outdir = output && (!output.startsWith("/") || !output.startsWith("s3://")) ? null : output
    workdir = work && (!work.startsWith("/") || !output.startsWith("s3://")) ? null : work

    def resume = !options.resume && file(task.scratch.toString()).exists() ? "-resume" : ""
    def paramsJson = new JsonBuilder(paramsMap).toPrettyString()
    def optionArgs = options.collect { k, v ->
        if(v == true) {
            "-${k}"
        } else {
            "-${k} ${v}"
        }
    }.join(" ")
    """
cd ..
echo '${paramsJson}' > params.json
nextflow run ${pipeline} \\
    -params-file params.json \\
    ${optionArgs} \\
    ${resume}
    """
}