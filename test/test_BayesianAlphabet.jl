using CSV,DataFrames,JWAS,JWAS.Datasets
phenofile       = Datasets.dataset("example","phenotypes.txt")
phenofile_ssbr  = Datasets.dataset("example","phenotypes_ssbr.txt")
pedfile    = Datasets.dataset("example","pedigree.txt")
genofile   = Datasets.dataset("example","genotypes.txt")
mapfile    = Datasets.dataset("example","map.txt")

phenotypes = CSV.read(phenofile,delim = ',',header=true,missingstrings=["NA"])
phenotypes_ssbr = CSV.read(phenofile_ssbr,delim = ',',header=true,missingstrings=["NA"])
pedigree   = get_pedigree(pedfile,separator=",",header=true);

if ispath("mytest") == true
      rm("mytest", recursive=true)
end
mkdir("mytest/")
cd("mytest/")
for single_step in [false,true]
      for test_method in ["GBLUP","BayesA","BayesC","BayesB","RR-BLUP","BayesL","conventional (no markers)"]
            newdir = "ST_"*(single_step ? "SS" : "")*test_method*"/"
            mkdir(newdir)
            cd(newdir)
            if test_method in ["BayesC","BayesB"]
                  test_estimatePi = true
            else
                  test_estimatePi = false
            end

            printstyled("\n\n\n\n\n\n\n\nTest single-trait $test_method analysis using $(single_step ? "in" : "")complete genomic data\n\n\n",bold=true,color=:green)

            model_equation1  ="y1 = intercept + x1*x3 + x2 + x3 + ID + dam";
            R      = 1.0
            model1 = build_model(model_equation1,R);

            set_covariate(model1,"x1");
            G1 = 1.0
            G2 = [1.0 0.5
                  0.5 1.0]
            set_random(model1,"ID dam",pedigree,G2);
            set_random(model1,"x2",G1);

            if test_method != "conventional (no markers)"
                  G3 =1.0
                  add_genotypes(model1,genofile,G3,header=true,separator=',');
            end
            outputMCMCsamples(model1,"x2")

            if single_step == false
                  out1=runMCMC(model1,phenotypes,estimate_variance=true,heterogeneous_residuals=false,
                               methods=test_method,estimatePi=test_estimatePi,double_precision=true,
                               chain_length=100,output_samples_frequency=10,
                               printout_frequency=50,output_samples_file = "MCMC_samples",seed=314);
            elseif single_step == true && test_method!="conventional (no markers)" && test_method!="GBLUP"
                  out1=runMCMC(model1,phenotypes_ssbr,estimate_variance=true,heterogeneous_residuals=false,
                              methods=test_method,estimatePi=test_estimatePi,chain_length=100,output_samples_frequency=10,printout_frequency=50,
                              single_step_analysis=true,pedigree=pedigree,output_samples_file = "MCMC_samples",seed=314);
            end
            if test_method != "conventional (no markers)" && test_method!="GBLUP"
                  gwas1=GWAS("MCMC_samples_marker_effects_y1.txt")
                  show(gwas1)
                  println()
                  gwas2=GWAS("MCMC_samples_marker_effects_y1.txt",mapfile,model1)
                  show(gwas2)
            end
            cd("..")

            printstyled("\n\n\n\n\n\n\n\nTest multi-trait $test_method analysis using $(single_step ? "in" : "")complete genomic data\n\n\n",bold=true,color=:green)

            newdir = "MT_"*(single_step ? "SS" : "")*test_method*"/"
            mkdir(newdir)
            cd(newdir)

            model_equation2 ="y1 = intercept + x1 + x3 + ID + dam
                              y2 = intercept + x1 + x2 + x3 + ID
                              y3 = intercept + x1 + x1*x3 + x2 + ID";

            R      = [1.0 0.5 0.5
                      0.5 1.0 0.5
                      0.5 0.5 1.0]
            model2 = build_model(model_equation2,R);

            set_covariate(model2,"x1");
            G1 = [1.0 0.5
                  0.5 1.0]
            G2 = [1.0 0.5 0.5 0.5
                  0.5 1.0 0.5 0.5
                  0.5 0.5 1.0 0.5
                  0.5 0.5 0.5 1.0]
            set_random(model2,"ID dam",pedigree,G2);
            set_random(model2,"x2",G1);

            if test_method != "conventional (no markers)"
                  G3 = [1.0 0.5 0.5
                        0.5 1.0 0.5
                        0.5 0.5 1.0]
                  add_genotypes(model2,genofile,G3,separator=',');
            end
            outputMCMCsamples(model2,"x2")

            if single_step == false
                  out2=runMCMC(model2,phenotypes,estimate_variance=true,heterogeneous_residuals=false,double_precision=true,
                              methods=test_method,estimatePi=test_estimatePi,chain_length=100,output_samples_frequency=10,printout_frequency=50,output_samples_file = "MCMC_samples",seed=314);
            elseif single_step == true && test_method!="conventional (no markers)" && test_method!="GBLUP"
                  out2=runMCMC(model2,phenotypes_ssbr,estimate_variance=true,heterogeneous_residuals=false,double_precision=true,
                              methods=test_method,estimatePi=test_estimatePi,chain_length=100,output_samples_frequency=10,printout_frequency=50,
                              single_step_analysis=true,pedigree=pedigree,output_samples_file = "MCMC_samples",seed=314);
            end
            if test_method != "conventional (no markers)" && test_method!="GBLUP"
                  gwas1=GWAS("MCMC_samples_marker_effects_y1.txt")
                  show(gwas1)
                  println()
                  gwas2=GWAS("MCMC_samples_marker_effects_y1.txt",mapfile,model2)
                  show(gwas2)
            end
            cd("..")
      end
end
cd("..")
