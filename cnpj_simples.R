
################################################## Simples #####################

setwd("data")

#################################################### Leituras ##################

source("X:/POWER BI/NOVOCAGED/conexao.R")

schema_name <- "ministerio_fazenda_cnpj"

table_name <- "cnpj_estabelecimentos"

cnpj_estabelecimentos <- RPostgres::dbReadTable(conexao,
                                                DBI::Id(schema= schema_name,
                                                        table = table_name))

RPostgres::dbDisconnect(conexao)

cnpj_estabelecimentos <- cnpj_estabelecimentos |> dplyr::select(cnpj_basico) |>
  unique()

# Fazendo conexão com o banco de dados

source("X:/POWER BI/NOVOCAGED/conexao.R")

RPostgres::dbListTables(conexao)

schema_name <- "ministerio_fazenda_cnpj"

table_name <- "cnpj_simples"

DBI::dbSendQuery(conexao, paste0("CREATE SCHEMA IF NOT EXISTS ", schema_name))


############ Estabelecimentos


cnpj_simples_endereco <- fs::dir_ls(glob = paste0("*Simples", "*.zip"))

cnpj_simples <-
  readr::read_csv2(cnpj_simples_endereco,
                   locale = readr::locale(encoding = "latin1",
                                          decimal_mark = ","),
                   col_names = F,
                   col_types = readr::cols(
                     "X3" = readr::col_date(format = "%Y%m%d"),
                     "X4" = readr::col_date(format = "%Y%m%d"),
                     "X6" = readr::col_date(format = "%Y%m%d"),
                     "X7" = readr::col_date(format = "%Y%m%d"),
                     .default = readr::col_character()
                   ))


# Nomeando Colunas

cnpj_simples <- cnpj_simples |> 
  dplyr::rename(cnpj_basico = 1,
                opcao_simples = 2,
                data_opcao_simples = 3,
                data_exclusao_simples = 4,
                opcao_mei = 5,
                data_opcao_mei = 6,
                data_exclusao_mei = 7
  )

cnpj_simples <- cnpj_simples |>
  dplyr::semi_join(cnpj_estabelecimentos, by = "cnpj_basico")

# writing PostgreSQL

RPostgres::dbWriteTable(
  conexao,
  name = DBI::Id(schema = schema_name, table = table_name),
  value = cnpj_simples,
  row.names = FALSE,
  overwrite = TRUE
)

RPostgres::dbDisconnect(conexao)
