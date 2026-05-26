#################################################### Decodificador #############
setwd("data")

cnpj_decodificador_enderecos <-
  fs::dir_ls(glob = "*Cnaes*.zip|*Motivos*.zip|*Municipios*.zip|*Naturezas*.zip|
           |*Paises*.zip|*Qualificacoes*.zip")

cnpj_decodificador_lista <- vector(mode = "list",
                                   length = length(cnpj_decodificador_enderecos))

for (i in seq_along(cnpj_decodificador_enderecos)){
  
  cnpj_decodificador_lista[[i]] <-
    readr::read_csv2(cnpj_decodificador_enderecos[i],
                     locale = readr::locale(encoding = "latin1",
                                            decimal_mark = ","),
                     col_names = F,
                     col_types = readr::cols(.default = readr::col_character()
                     ))
  
}

cnpj_decodificador_lista[[1]] <- cnpj_decodificador_lista[[1]] |>
  dplyr::rename(cnaes = 1, cnaes_decodificado = 2)

cnpj_decodificador_lista[[2]] <- cnpj_decodificador_lista[[2]] |>
  dplyr::rename(motivos_situacao_cadastral = 1,
                motivos_situacao_cadastral_decodificado = 2)

cnpj_decodificador_lista[[3]] <- cnpj_decodificador_lista[[3]] |>
  dplyr::rename(municipios = 1, municipios_decodificado = 2)

cnpj_decodificador_lista[[4]] <- cnpj_decodificador_lista[[4]] |>
  dplyr::rename(natureza_juridica = 1, natureza_juridica_decodificado = 2)

cnpj_decodificador_lista[[5]] <- cnpj_decodificador_lista[[5]] |>
  dplyr::rename(paises = 1, paises_decodificado = 2)

cnpj_decodificador_lista[[6]] <- cnpj_decodificador_lista[[6]] |>
  dplyr::rename(qualificacao_responsavel = 1,
                qualificacao_responsavel_decodificado = 2)

#################################################### Leituras ##################

source("X:/POWER BI/NOVOCAGED/conexao.R")

teste <- RPostgres::dbListTables(conexao)

schema_name <- "ministerio_fazenda_cnpj"

table_name <- "cnpj_estabelecimentos"

cnpj_estabelecimentos <- RPostgres::dbReadTable(conexao,
                                                DBI::Id(schema= schema_name,
                                                        table = table_name))

RPostgres::dbDisconnect(conexao)

cnpj_estabelecimentos <- cnpj_estabelecimentos |> dplyr::select(cnpj_basico) |>
  unique()

################################################## Estabelecimentos ############


# Fazendo conexão com o banco de dados

source("X:/POWER BI/NOVOCAGED/conexao.R")

RPostgres::dbListTables(conexao)

schema_name <- "ministerio_fazenda_cnpj"

table_name <- "cnpj_socios"

DBI::dbSendQuery(conexao, paste0("CREATE SCHEMA IF NOT EXISTS ", schema_name))


############ Estabelecimentos

cnpj_arquivos <- 0:9

# Loop para ler arquivos por vez
for (h in cnpj_arquivos) {
  
  cnpj_socios_endereco <-
    fs::dir_ls(glob = paste0("*Socios", h,"*.zip"))
  
  cnpj_socios_lista <- vector(
    mode = "list", length = length(cnpj_socios_endereco))
  
  
  for(i in seq_along(cnpj_socios_endereco)){
    
    cnpj_socios_lista[[i]] <-
      readr::read_csv2(cnpj_socios_endereco,
                       locale = readr::locale(encoding = "latin1",
                                              decimal_mark = ","),
                       col_names = F,
                       col_types = readr::cols(
                         #"X6" = readr::col_date(format = "%Y%m%d"),
                         .default = readr::col_character()
                       ))
  }
  
  # Nomeando Colunas
  cnpj_socios <- cnpj_socios_lista |>
    dplyr::bind_rows() |>
    dplyr::rename(cnpj_basico = 1,
                  identificador_de_socio = 2,
                  nome_socio = 3,
                  cnpj_cpf_socio = 4,
                  qualificacao_socio = 5,
                  data_entrada_sociedade = 6,
                  paises = 7,
                  cpf_representante_legal = 8,
                  nome_representante_legal = 9,
                  qualificacao_representante_legal = 10,
                  faixa_etaria =11,
    )
  
  # Decodificado Dicionario
  for(j in seq_along(cnpj_decodificador_lista)){
    tryCatch({
      cnpj_socios <- cnpj_socios |>
        dplyr::left_join(cnpj_decodificador_lista[[j]])
    }, error = function(err) {warning("file could not be join")})
  }
  
  cnpj_socios <- cnpj_socios |>
    dplyr::select(- paises)
  
  # Decodificando Manual
  
  cnpj_socios <- cnpj_socios |>
    dplyr::mutate(identificador_de_socio =
                    dplyr::case_when(
                      identificador_de_socio == "1" ~ "PESSOA JURÍDICA",
                      identificador_de_socio == "2" ~ "PESSOA FISICA",
                      identificador_de_socio == "3" ~ "ESTRANGEIRO"),
                  .keep = "unused"
    )
  
  cnpj_socios <- cnpj_socios |>
    dplyr::mutate(faixa_etaria =
                    dplyr::case_when(
                      faixa_etaria == "1" ~ "0 a 12 anos",
                      faixa_etaria == "2" ~ "13 a 20 anos",
                      faixa_etaria == "3" ~ "21 a 30 anos",
                      faixa_etaria == "4" ~ "31 a 40 anos",
                      faixa_etaria == "5" ~ "41 a 50 anos",
                      faixa_etaria == "6" ~ "51 a 60 anos",
                      faixa_etaria == "7" ~ "61 a 70 anos",
                      faixa_etaria == "8" ~ "71 a 80 anos",
                      faixa_etaria == "9" ~ "maiores de 80 anos",
                      faixa_etaria == "9" ~ "Não se aplica"),
                  .keep = "unused"
    )
  
  cnpj_socios <- cnpj_socios |> 
    dplyr::left_join(cnpj_decodificador_lista[[6]],
                     dplyr::join_by(qualificacao_socio ==
                                      qualificacao_responsavel)) |>
    dplyr::select(-qualificacao_socio) |>
    dplyr::rename(qualificacao_socio = qualificacao_responsavel_decodificado)
  
  cnpj_socios <- cnpj_socios |> 
    dplyr::left_join(cnpj_decodificador_lista[[6]],
                     dplyr::join_by(qualificacao_representante_legal ==
                                      qualificacao_responsavel)) |>
    dplyr::select(-qualificacao_representante_legal) |>
    dplyr::rename(qualificacao_representante_legal =
                    qualificacao_responsavel_decodificado)
  
  cnpj_socios <- cnpj_socios |>
    dplyr::semi_join(cnpj_estabelecimentos, by = "cnpj_basico")
  
  # writing PostgreSQL
  if (h == 0) {
    RPostgres::dbWriteTable(
      conexao,
      name = DBI::Id(schema = schema_name, table = table_name),
      value = cnpj_socios,
      row.names = FALSE,
      overwrite = TRUE
    )
  } else {
    # Inserir os dados na tabela existente (append = TRUE)
    RPostgres::dbWriteTable(
      conexao,
      name = DBI::Id(schema = schema_name, table = table_name),
      value = cnpj_socios,
      row.names = FALSE,
      append = TRUE
    )
  }
  
  cnpj_socios |> dplyr::glimpse()
  print(h) 
} #fim do loop

RPostgres::dbDisconnect(conexao)
