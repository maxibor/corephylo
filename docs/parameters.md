

# maxibor/corephylo pipeline parameters                                                                                                   
                                                                                                                                          
Core genome based phylogenetic analysis                                                                                                   
                                                                                                                                          
## Input/output options                                                                                                                   
                                                                                                                                          
Define where the pipeline should find input data and save output data.                                                                    
                                                                                                                                          
| Parameter | Description | Type | Default | Required | Hidden |                                                                          
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                 
| `genomes` | Path to genome input sheet <details><summary>Help</summary><small>Path to genome sample sheet</small></details>| `string` | | `True`
| `bakta_db` | Path to bakta database | `string` |  | `True` |  |                                                                           
| `outdir` | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure. | `string` 
| `email` | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail address to get 
                                                                                                                                          
## corephylo parameters                                                                                                                   
                                                                                                                                          
Parameters specific to the corephylo pipeline                                                                                             
                                                                                                                                          
| Parameter | Description | Type | Default | Required | Hidden |                                                                          
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                 
| `core_threshold` | core genome threshold for Panaroo <details><summary>Help</summary><small>See panaroo documentation for more information | `float` | `0.95`
| `iqtree_cpu_auto` | Let IQTREE decide the best number of CPUs to use Help <details><summary>Help</summary>See IQTREE documentation for more information | `boolean` | `false`
| `iqtree_no_bootstrap` | Deactive UFBootstrap in IQTree | `boolean` | `false` |  |  |                                                           
| `iqtree_no_bnni` | Deactive bnni in IQTREE <details><summary>Help</summary><small>UFBoot trees by nearest neighbor interchange (NNI) | `boolean` | `false`
                                                                                                                                          
## Institutional config options                                                                                                           
                                                                                                                                          
Parameters used to describe centralised config profiles. These should not be edited.                                                      
                                                                                                                                          
| Parameter | Description | Type | Default | Required | Hidden |                                                                          
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                 
| `custom_config_version` | Git commit id for Institutional configs. | `string` | master |  | True |                                      
| `custom_config_base` | Base directory for Institutional configs. <details><summary>Help</summary><small>If you're running offline, Nextf
| `config_profile_name` | Institutional config name. | `string` |  |  | True |                                                            
| `config_profile_description` | Institutional config description. | `string` |  |  | True |                                              
| `config_profile_contact` | Institutional config contact information. | `string` |  |  | True |                                          
| `config_profile_url` | Institutional config URL link. | `string` |  |  | True |                                                         
                                                                                                                                          
## Max job request options                                                                                                                
                                                                                                                                          
Set the top limit for requested resources for any single job.                                                                             
                                                                                                                                          
| Parameter | Description | Type | Default | Required | Hidden |                                                                          
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                 
| `max_cpus` | Maximum number of CPUs that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper
| `max_memory` | Maximum amount of memory that can be requested for any single job. <details><summary>Help</summary><small>Use to set an u
| `max_time` | Maximum amount of time that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper
                                                                                                                                          
## Generic options                                                                                                                        
                                                                                                                                          
Less common options for the pipeline, typically set in a config file.                                                                     
                                                                                                                                          
| Parameter | Description | Type | Default | Required | Hidden |                                                                          
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                 
| `help` | Display help text. | `boolean` |  |  | True |                                                                                  
| `publish_dir_mode` | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publ
| `email_on_fail` | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An email addres
| `plaintext_email` | Send plain-text email instead of HTML. | `boolean` |  |  | True |                                                   
| `monochrome_logs` | Do not use coloured log outputs. | `boolean` |  |  | True |                                                         
| `hook_url` | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging service. Cur
| `tracedir` | Directory to keep pipeline Nextflow logs and reports. | `string` | null/pipeline_info |  | True |                          
| `validate_params` | Boolean whether to validate parameters against the schema at runtime | `boolean` | True |  | True |                 
| `show_hidden_params` | Show all params when using `--help` <details><summary>Help</summary><small>By default, parameters set as _hidden_
| `enable_conda` | Run this workflow with Conda. You can also use '-profile conda' instead of providing this parameter. | `boolean` |  |  
| `schema_ignore_params` |  | `string` | monochromeLogs,validationS3PathCheck,validationSkipDuplicateCheck,validationSchemaIgnoreParams,va
                                                                                                                                          


