# ----------------------------------------------------------------------
# Download de arquivos do CNPJ da Receita Federal (dados públicos)
# ----------------------------------------------------------------------

# https://arquivos.receitafederal.gov.br/index.php/s/gn672Ad4CF8N6TK?dir=/Dados/Cadastros/CNPJ


# Gera os dois últimos meses (mês atual e mês anterior) para tentativa
ano_messes <- c(format(lubridate::today(), "%Y-%m"),
                format(lubridate::add_with_rollback(lubridate::today(),
                                                    months(-1)), "%Y-%m"))

requisicao <- NULL

for(m in ano_messes) {
  
  endereco <- paste0("https://arquivos.receitafederal.gov.br/public.php/",
                     "dav/files/gn672Ad4CF8N6TK/Dados/Cadastros/CNPJ/",
                     m, "/")
  
  cat("Verificando:", endereco, "\n")
  
  requisicao <- httr::VERB(verb = "PROPFIND",
                           url = endereco,
                           httr::add_headers(Depth = "1"))
  
  status <- httr::status_code(requisicao)
  if (status != 404) {
    cat("Diretório encontrado para", m, "(status:", status, ")\n")
    break
  } else {
    cat("Diretório não encontrado para", m, "\n")
  }
}

# Verifica se a requisição foi bem-sucedida (status 200 ou 207)
if (is.null(requisicao) || !(httr::status_code(requisicao) %in% c(200, 207))) {
  stop(sprintf("Falha na requisição: status %s. Nenhum dado obtido.",
               httr::status_code(requisicao)))
}

# Extrai o XML da resposta
xml_txt <- httr::content(requisicao, as = "text", encoding = "UTF-8")
documento <- xml2::read_xml(xml_txt)

# Obtém os hrefs (caminhos) dos arquivos
ns <- xml2::xml_ns(documento)
hrefs <- xml2::xml_find_all(documento, ".//d:href", ns) |> 
  xml2::xml_text()

# Filtra apenas arquivos .zip
hrefs <- hrefs[stringr::str_detect(hrefs, "\\.zip$")]

if (length(hrefs) == 0) {
  stop("Nenhum arquivo .zip encontrado no diretório.")
}

# Monta URLs completas e nomes locais
links_download <- paste0("https://arquivos.receitafederal.gov.br", hrefs)
nomes_arquivos <- basename(links_download)

# Cria pasta de destino
dir.create("data", showWarnings = FALSE)

# Download com retry automático
for(i in seq_along(links_download)) {
  
  sucesso <- FALSE
  tentativa <- 1
  
  while (!sucesso) {
    tryCatch({
      
      destino <- file.path("data", nomes_arquivos[i])
      
      message(sprintf("[%d/%d] Baixando: %s (tentativa %d)", 
                      i, length(links_download), nomes_arquivos[i], tentativa))
      
      httr::GET(links_download[i],
                httr::write_disk(destino, overwrite = TRUE),
                httr::progress())
      
      sucesso <- TRUE
      message("  -> Concluído!")
      
    }, error = function(e) {
      warning(sprintf("Erro ao baixar %s: %s", nomes_arquivos[i], e$message))
      cat("  -> Nova tentativa em 5 segundos...\n")
      Sys.sleep(5)
      tentativa <<- tentativa + 1
    })
    
    if (tentativa > 10) {
      stop(sprintf("Falha após 10 tentativas para o arquivo %s", nomes_arquivos[i]))
    }
  }
}

cat("\nTodos os arquivos foram baixados com sucesso em 'data/'\n")
