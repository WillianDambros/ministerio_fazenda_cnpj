########################### Arquivo Executável Atualização CNPJ ################

caminho_comum <- paste0(getwd(), "/")

#source(paste0(caminho_comum, "cnpj_download.R"))
#setwd(caminho_comum)

source(paste0(caminho_comum, "cnpj_estabelecimentos.R"))
setwd(caminho_comum)

source(paste0(caminho_comum, "cnpj_empresas.R"))
setwd(caminho_comum)

source(paste0(caminho_comum, "cnpj_socios.R"))
setwd(caminho_comum)

source(paste0(caminho_comum, "cnpj_simples.R"))
setwd(caminho_comum)

tempdir()
list.files(tempdir(), full.names = TRUE)
unlink(list.files(tempdir(), full.names = TRUE), recursive = TRUE)