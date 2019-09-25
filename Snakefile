configfile: "config.yaml"
singularity: "docker://continuumio/miniconda3:4.7.10"

rule all:
    input:
        expand('kraken_reports/{sample}.kraken2.txt', sample=config["sample_names"]),
        expand('kraken_reports/{sample}.kraken2.report.txt', sample=config["sample_names"]),
        expand('centrifuge_reports/{sample}.centrifuge.txt', sample=config["sample_names"]),
        expand('centrifuge_reports/{sample}.centrifuge.report.txt', sample=config["sample_names"])

rule kraken2:
    input:
        expand('{in_dir}/{{sample}}_{dir}.fastq.gz', in_dir=config["patric_dir"], dir=['1', '2'])
    output:
        out='kraken_reports/{sample}.kraken2.txt',
        report='kraken_reports/{sample}.kraken2.report.txt'
    conda:
        "envs/kraken2.yaml"
    params:
        db=config['kraken_db']
    shell:
        'kraken2 --threads {threads} --db {params.db} --output {output.out} --report {output.report} {input}'

rule centrifuge:
    input:
        r1=expand('{in_dir}/{{sample}}_1.fastq.gz', in_dir=config["patric_dir"]),
        r2=expand('{in_dir}/{{sample}}_2.fastq.gz', in_dir=config["patric_dir"])
    output:
        out='centrifuge_reports/{sample}.centrifuge.txt',
        report='centrifuge_reports/{sample}.centrifuge.report.txt'
    conda:
        "envs/centrifuge.yaml"
    params:
        db=config['centrifuge_db']
    shell:
        'centrifuge --threads {threads} -x {params.db} -1 {input.r1} -2 {input.r2} -S {output.out} --report-file {output.report}'
