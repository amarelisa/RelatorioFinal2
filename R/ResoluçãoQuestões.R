# Relatório final do curso "Ciência de Dados II" da Curso-R
# Maria Elisa Rocha Couto Gomes
# Conectando o GitHub

library(usethis)
use_git()
use_github()

# Instalando pacote "basesCursoR"

remotes::install_github("curso-r/basesCursoR", force = TRUE)


imdb_completa <- basesCursoR::pegar_base("imdb_completa")
imdb_pessoas <- basesCursoR::pegar_base("imdb_pessoas")
imdb_avaliacoes <- basesCursoR::pegar_base("imdb_avaliacoes")

# Salvando as bases de dados

library(writexl)

write.csv2(imdb_completa, "data_raw/imdb_completa.csv")
write.csv2(imdb_avaliacoes, "data_raw/imdb_avaliacoes.csv")
write.csv2(imdb_pessoas, "data_raw/imdb_pessoas.csv")

library(readr)

write_rds(imdb_completa, "data/imdb_completa.rds")
write_rds(imdb_avaliacoes, "data/imdb_avaliacoes.rds")
write_rds(imdb_pessoas, "data/imdb_pessoas.rds")

# 1. Qual o mês do ano com o maior númedo de filmes? E o dia do ano?

# Carregando os pacotes necessários para responder à pergunta:

library(tidyverse)
library(dplyr)
library(forcats)
library(lubridate)
library(knitr)
library(tibble)

# Verificando qual mês teve o maior número de filmes: 

recorde_filme_mes <- imdb_completa %>%
  mutate(data_config = as.Date(ymd(data_lancamento))) %>%
  mutate(mês = month(data_config)) %>% 
  filter(across(c(mês, ano), ~ !is.na(.))) %>% 
  mutate(mês_ano = paste(mês, ano, sep = "/")) %>% 
  group_by(mês_ano) %>% 
  mutate(n_filmes = n_distinct(titulo)) %>% 
  ungroup() %>% 
  nest_by(mês_ano, n_filmes) %>% 
  arrange(desc(n_filmes)) %>% 
  head(1) %>% 
  mutate(pos = 1) %>% 
  select('Posição' = pos, 'Mês/Ano' = mês_ano, 'Número de lançamentos' = n_filmes) %>%
  kable()

recorde_filme_mes

# Verificando qual dia teve o maior número de filmes:

recorde_filme_dia <- imdb_completa %>% 
  mutate(data_config = as.Date(ymd(data_lancamento))) %>%  
  mutate(mês = month(data_config)) %>% 
  mutate(dia = day(data_config)) %>% 
  filter(across(c(dia, mês, ano), ~ !is.na(.))) %>% 
  mutate(dia_mês_ano = paste(dia, mês, ano, sep = "/")) %>% 
  group_by(dia_mês_ano) %>% 
  mutate(n_filmes = n_distinct(titulo)) %>% 
  ungroup() %>% 
  nest_by(dia_mês_ano, n_filmes) %>% 
  arrange(desc(n_filmes)) %>% 
  head(1) %>% 
  mutate(pos = 1) %>% 
  select('Posição' = pos, 'Dia/Mês/Ano' = dia_mês_ano, 'Número de Lançamentos' = n_filmes) %>% 
  kable()

recorde_filme_dia

# 2. Qual o top 5 países com mais filmes na base?

# Identificando o top 5 países com mais filmes na base IMDB:

top_paises_filmes <- imdb_completa %>%
  filter(!is.na(pais)) %>% 
  mutate(pais_nova = str_split(pais, ", ")) %>% 
  unnest(pais_nova) %>% 
  group_by(pais_nova) %>% 
  mutate(n_filmes_pais = n_distinct(titulo)) %>%
  ungroup() %>% 
  nest_by(pais_nova, n_filmes_pais) %>% 
  arrange(desc(n_filmes_pais)) %>% 
  head(5) %>% 
  rowid_to_column(var = "pos") %>% 
  select('Posição' = pos, 'País' = pais_nova, 'Número de filmes' = n_filmes_pais) %>% 
  kable()

top_paises_filmes


# 3. Liste todas as moedas que aparecem nas colunas orcamento e receita da base 
# imdb_completa.

# Carregando pacotes que utilizarei para responder a esta pergunta:

library(stringr)
library(readr)
library(readxl)

# Identificando quais são as moedas dos orçamentos e das receitas dos filmes contidos na base IMDB:

moedas_receita_orcamento <- imdb_completa %>% 
  filter(across(c(orcamento, receita), ~!is.na(.))) %>% 
  summarise(across(
    .cols = c(orcamento, receita),
    .fns = ~ str_extract((.x), pattern = c("^.[[:blank:][:digit:]]", "\\X+?[[:blank:][:digit:]]")))) %>% 
  filter(across(c(orcamento, receita), ~!is.na(.))) %>% 
  summarise(across(
    .cols = c(orcamento, receita),
    .fns = ~ str_replace_all((.x), pattern = " ", "")))

# Importando banco de dados que contém mais informações sobre as moedas que foram identificadas:

lista_moedas <- read_excel("data_raw/lista_moedas.xlsx",
                           na = c("Nenhum", "none"))
View(lista_moedas)

write_rds(lista_moedas, "data/lista_moedas.rds")

# Listando as moedas dos orçamentos dos filmes contidos na base IMDB:

moedas_orcamento <- moedas_receita_orcamento %>%
  nest_by(orcamento) %>% 
  mutate(orcamento = case_when(
    orcamento == "$" ~ "USD",
    TRUE ~ as.character(as.character(orcamento)))) %>% 
  left_join(lista_moedas, by = "orcamento", copy = TRUE) %>% 
  select('Código das moedas dos orçamentos dos filmes' = orcamento, 'Nome da moeda' = nome) %>% 
  kable()

moedas_orcamento

# Listando as moedas das receitas dos filmes contidos na base IMDB:

moedas_receita <- moedas_receita_orcamento %>%
  nest_by(receita) %>% 
  mutate(receita = case_when(
    receita == "$" ~ "USD",
    TRUE ~ as.character(as.character(receita)))) %>% 
  left_join(lista_moedas, by = "receita", copy = TRUE) %>% 
  select('Código das moedas das receitas dos filmes' = receita, 'Nome da moeda' = nome) %>% 
  kable()

moedas_receita

# 4. Considerando apenas orçamentos e receitas em dólar ($), qual o gênero com
# maior lucro? E com maior nota média?

# Identificando qual é o gênero do filme que teve o maior lucro

genero_maior_lucro <- imdb_completa %>% 
  filter(across(c(orcamento, receita), ~!is.na(.), ~ str_detect((.x), pattern = "^.[[:blank:][:digit:]]"))) %>% 
  mutate(across(
    .cols = c(orcamento, receita),
    .fns = c(~ str_extract((.x), pattern = ".[[:digit:]]+!*")))) %>% 
  mutate(across(
    .cols = c(orcamento_1, receita_1),
    .fns = ~ as.numeric(.x))) %>%
  mutate(lucro = receita_1 - orcamento_1) %>%
  filter(across(c(genero, lucro), ~!is.na(.))) %>% 
  mutate(genero = str_split(genero, ", ")) %>% 
  unnest(genero) %>%
  nest_by(titulo, genero, lucro) %>% 
  arrange(desc(lucro)) %>% 
  head(1, lucro) %>% 
  select("Título"= titulo, "Gênero" = genero, "Lucro" = lucro) %>% 
  kable()

genero_maior_lucro


# Identificando qual é o gênero do filme que obteve a maior nota média

genero_maior_nota <- imdb_completa %>% 
  left_join(imdb_avaliacoes, by = "id_filme", copy = TRUE) %>% 
  filter(across(c(genero, nota_media), ~!is.na(.))) %>% 
  mutate(genero = str_split(genero, ", ")) %>% 
  unnest(genero) %>% 
  nest_by(titulo, genero, nota_media) %>% 
  arrange(desc(nota_media)) %>% 
  head(1, nota_media) %>% 
  select('Título' = titulo, 'Gênero' = genero, 'Nota média' = nota_media) %>% 
  kable()

genero_maior_nota


# 5. Dentre os filmes na base imdb_completa, escolha o seu favorito. Então faça 
# os itens a seguir: a) Quem dirigiu o filme? Faça uma ficha dessa pessoa: idade 
# (hoje em dia ou data de falecimento), onde nasceu, quantos filmes já dirigiu, 
# qual o lucro médio dos filmes que dirigiu (considerando apenas valores em dólar) 
# e outras informações que achar interessante (base imdb_pessoas).

# Verificando qual é o nome do diretor do filme

hair_nome_direcao <- imdb_completa %>% 
  filter(str_detect(titulo, pattern = "Hair$")) %>% 
  select('Nome do diretor(a)' = direcao)

hair_nome_direcao

# Calculando a idade que o diretor de "Hair" tinha quando faleceu

milos_idade_falecimento <- imdb_pessoas %>% 
  filter(str_detect(nome, pattern = "Milos Forman")) %>%
  mutate(across(
    .cols = c(data_nascimento, data_falecimento),
    .fns = ~ as.Date(ymd(.)))) %>% 
  mutate(idade_falecimento = as.period(data_falecimento - data_nascimento)/years(1))

# Calculando quantos filmes, além de "Hair", ele dirigiu

milos_n_filmes <- imdb_completa %>% 
  filter(str_detect(direcao, pattern = "Milos Forman")) %>% 
  filter(str_detect(titulo, pattern = "Hair$", negate = TRUE)) %>% 
  summarise(n_filmes = n_distinct(titulo))

# Calculando os lucros médios dos filmes dirigidos por Milos Forman

milos_lucro_medio <- imdb_completa %>% 
  filter(str_detect(direcao, pattern = "Milos Forman")) %>% 
  filter(across(c(receita, orcamento), ~!is.na(.), str_detect((.x), pattern = "^.[[:blank:][:digit:]]"))) %>% 
  mutate(across(
    .cols = c(orcamento, receita),
    .fns = ~ (str_extract((.x), pattern = ".[[:digit:]]+!*")))) %>% 
  mutate(across(
    .cols = c(orcamento, receita),
    .fns = ~ as.numeric(.x))) %>% 
  mutate(lucro = receita - orcamento) %>% 
  summarise(lucro_medio = mean(lucro))

# Calculando a frequência relativa de cada um dos gêneros dos filmes que Milos Forman dirigiu

milos_generos_freq <- imdb_completa %>% 
  filter(str_detect(direcao, pattern = "Milos Forman")) %>% 
  mutate(genero = str_split(genero, pattern = ", ")) %>%   unnest(genero) %>% 
  group_by(genero) %>% 
  summarise(n = n(), na.rm = TRUE) %>% 
  mutate(freq_genero = n/sum(n)) %>% 
  mutate(freq_genero = freq_genero*100) %>% 
  mutate(freq_genero = round(freq_genero, 2)) %>% 
  arrange(desc(freq_genero)) %>% 
  select('Gênero' = genero, 'Frequência relativa' = freq_genero) %>% 
  kable()

# b) Qual a posição desse filme no ranking de notas do IMDB? E no ranking de 
# lucro (considerando apenas valores em dólar)?

# Calculando a posição de "Hair" no ranking de notas do IMDB

posicao_nota_hair <- imdb_completa %>% 
  left_join(imdb_avaliacoes, by = "id_filme", copy = TRUE) %>% 
  group_by(nota_media) %>% 
  arrange(desc(nota_media)) %>% 
  rowid_to_column(var = "pos") %>%
  filter(str_detect(titulo, pattern = "Hair$")) %>% 
  select('Filme' = titulo, 'Nota média' = nota_media, 'Posição' = pos) %>% 
  kable()

posicao_nota_hair

# Calculando a posição de "Hair" no ranking de notas do IMDB

posicao_lucro_hair <- imdb_completa %>% 
  filter(across(c(receita, orcamento), ~!is.na(.), str_detect((.x), pattern = "^.[[:blank:][:digit:]]"))) %>% 
  mutate(across(
    .cols = c(orcamento, receita),
    .fns = ~ (str_extract((.x), pattern = ".[[:digit:]]+!*")))) %>% 
  mutate(across(
    .cols = c(orcamento, receita),
    .fns = ~ as.numeric(.x))) %>% 
  mutate(lucro = receita - orcamento) %>% 
  group_by(lucro) %>% 
  arrange(desc(lucro)) %>% 
  rowid_to_column(var = "pos") %>% 
  filter(str_detect(titulo, "Hair$")) %>% 
  select("Filme" = titulo, "Lucro" = lucro, "Posição" = pos) %>% 
  kable()

posicao_lucro_hair


# c) Em que dia esse filme foi lançado? E dia da semana? Algum outro filme foi 
# lançado no mesmo dia? Quantos anos você tinha nesse dia?

# Data de lançamento do filme hair

data_lancamento_hair <- imdb_completa %>% 
  filter(str_detect(titulo, pattern = "Hair$")) %>% 
  summarise(data_lancamento = as.Date(ymd(data_lancamento))) 

data_lancamento_hair

# Outros filmes que foram lançados no mesmo dia

outros_filmes_lancados <- imdb_completa %>% 
  filter(str_detect(titulo, pattern = "Hair$", negate = TRUE)) %>% 
  filter(str_detect(data_lancamento, pattern = "1979-05-16"))

outros_filmes_lancados

# Calculando a minha idade quando o filme foi lançado

minha_idade <- imdb_completa %>% 
  filter(str_detect(titulo, pattern = "Hair$")) %>% 
  mutate(data_lancamento = as.Date(ymd(data_lancamento)))  %>% 
  summarise(minha_idade = as.period(data_lancamento - as.Date(dmy("05 nov 1997")))/years(1)) %>% 
  mutate(minha_idade = round(minha_idade, 2))

minha_idade

# d) Faça um gráfico representando a distribuição da nota atribuída a esse filme 
# por idade (base imdb_avaliacoes).

# Carregando os pacotes que irei utilizar para elaborar este gráfico:

library(ggplot2)

# Selecionando os valores das variáveis correspondentes às notas médias por 
# faixa etária

notas <- imdb_completa %>% 
  left_join(imdb_avaliacoes, by = "id_filme", copy = TRUE) %>% 
  filter(str_detect(titulo, pattern = "Hair$")) %>% 
  select(nota_media_idade_0_18, nota_media_idade_18_30, 
         nota_media_idade_30_45, nota_media_idade_45_mais) %>%
  summarise(nota_media = as.numeric(c(nota_media_idade_0_18,
                                      nota_media_idade_18_30,
                                      nota_media_idade_30_45,
                                      nota_media_idade_45_mais))) %>% 
  rowid_to_column()

# Criando uma lista com categorias para cada uma das faixas etárias cujas notas 
# médias estão disponíveis em imdb_avaliacoes
  
faixa_etaria <- list((1:4), c("0 a 18 anos", "18 a 30 anos", "30 a 45 anos",
                       "45 anos ou mais"))
names(faixa_etaria) <- c("rowid", "faixa_etaria")

faixa_etaria <- as.data.frame(faixa_etaria)

# Elaborando gráfico sobre as notas médias das avaliações do filme "Hair" por 
# faixa etária

grafico_avaliacoes_idade <- notas %>%
  left_join(faixa_etaria, by = "rowid", copy = TRUE) %>%
  select(nota_media, faixa_etaria) %>% 
  ggplot(aes(x = faixa_etaria, y = nota_media, fill = faixa_etaria)) +
  geom_col(stat = "identity", show.legend = TRUE) +
  geom_label(aes(label = nota_media), show.legend = FALSE) +
  scale_fill_discrete() +
  ylim(0, 10) +
  labs(title = "Figura 1 - Nota média das avaliações recebidas pelo filme \"Hair\" por faixa etária",
       y = "Nota média das avaliações",
      fill = "Faixa etária",
       caption = "Fonte: IMDB")+
  theme_minimal() +
  theme(strip.text = element_text(size = 12),
        axis.text.x = element_blank(),
        axis.title.x = element_blank(),
        axis.line.x = element_blank(),
        axis.title.y = element_text(size = 8),
        strip.text.y = element_text(angle = 0),
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
        legend.title = element_text(hjust = 0.5, size = 8),
        legend.text = element_text(size = 7.5),
        legend.key.size = unit(0.5, 'cm'), 
        legend.key.height = unit(0.5, 'cm'),
        legend.key.width = unit(0.5, 'cm'),
        legend.spacing.y = unit(0.5, 'cm'),
        plot.caption = element_text(hjust = 0.5))


grafico_avaliacoes_idade


