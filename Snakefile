from __future__ import print_function

configfile: "config.yaml"
singularity: "docker://continuumio/miniconda3:4.7.10"

import os
def reports(tool, suffix):
    """reports(tool, suffix)
    tool - tool output configuration variable in config.yaml, e.g. 'kraken2_output_dir'
    suffix - suffix for the report e.g. 'kraken2.txt' or 'kraken2.report.txt'

    Generate a list of required output filenames from kraken2 or centrifuge tools"""
    sample_names = sorted(list(set([ name.split('_')[0] for name in os.listdir(config['patric_dir']) if not name.startswith('.') ])))
    # sample_names = sample_names[-2:]  # limit put in for testing
    return ([ config[tool] + '/' + name + suffix for name in sample_names ])

rule all:
    input:
        'merged/SA_genomes_from_PATRIC_annotated.csv'

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

rule merge_kraken2:
    input:
        reports('kraken2_report_dir', '.kraken2.report.txt')
    output:
        'merged/kraken2.txt'
    run:
        import os.path
        import sys
        with open(output[0], 'w') as out_file:
            for filename in input:
                sample_name = os.path.basename(filename).split('.')[0]
                with open(filename) as infile:
                    mycobacterium_read_total = 0
                    total_read_count = 0
                    for line in infile:
                        fields = line.split('\t')
                        if fields[-1].strip() in ('unclassified', 'root'):
                            total_read_count += int(fields[1])
                        elif fields[-1].strip().startswith('Mycobacterium'):
                            mycobacterium_read_total += int(fields[2])
                    mycobacterium_percentage = round(float(mycobacterium_read_total) / total_read_count * 100, ndigits=2)
                    print(sample_name, mycobacterium_percentage, sep='\t', file=out_file)


rule merge_centrifuge:
    input:
        reports('centrifuge_report_dir', '.centrifuge.report.txt')
    output:
        'merged/centrifuge.txt'
    run:
        import os.path
        import sys
        with open(output[0], 'w') as out_file:
            for filename in input:
                sample_name = os.path.basename(filename).split('.')[0]
                with open(filename) as infile:
                    for line in infile:
                        if line.startswith('Mycobacterium tuberculosis\t'):
                            fields = line.split()
                            percentage = round(float(fields[-1]) * 100, ndigits=2)
                            print(sample_name, percentage, sep='\t', file=out_file)

rule merge_with_patric:
    input:
        'SA_genomes_from_PATRIC.csv',
        'merged/kraken2.txt',
        'merged/centrifuge.txt'
    output:
        'merged/SA_genomes_from_PATRIC_annotated.csv'
    run:
        import csv

        def read_results_file(filename):
            results = dict()
            with open(filename) as in_file:
                for line in in_file:
                    fields = line.strip().split()
                    results[fields[0]] = fields[1]
            return results

        metadata_filename = input[0]
        kraken2_filename = input[1]
        centrifuge_filename = input[2]

        sample_kraken2_perc = read_results_file(kraken2_filename)
        sample_centrifuge_perc = read_results_file(centrifuge_filename)
        output_filename = output[0]
        
        reader = csv.reader(open(metadata_filename))
        header = next(reader)
        header.append('Kraken2 TB %')
        header.append('Centrifuge TB %')
        with open(output_filename, 'w') as out_file:
            writer = csv.writer(out_file)
            for row in reader:
                # row[18] is the SRA Accession column
                if "," in row[18]:
                    SRA_accession = row[18].split(',')[0].strip()
                elif row[18].strip() != '':
                    SRA_accession = row[18].strip()  # discard all SRA accessions besides the first for simplicity's sake
                else:
                    SRA_accession = None

                if SRA_accession and SRA_accession in sample_kraken2_perc:
                    row.append(sample_kraken2_perc[SRA_accession])
                else:
                    row.append('')

                if SRA_accession and SRA_accession in sample_centrifuge_perc:
                    row.append(sample_centrifuge_perc[SRA_accession])
                else:
                    row.append('')
                
                writer.writerow(row)
            