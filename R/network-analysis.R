# R/network-analysis.R
# Reusable helpers for building, summarizing, and visualizing networks via igraph.
# Source this file from the analysis pipeline: source("R/network-analysis.R")

# ---- make_graph ------------------------------------------------------------
#' Build an igraph object from an edge list and (optional) node attributes.
#'
#' @param edges      data.frame with columns `from`, `to`, and optional `weight`.
#' @param directed   logical.
#' @param node_attrs optional data.frame with an `id` column matching edge
#'                   endpoints plus any attribute columns.
#' @return            igraph object.
make_graph <- function(edges, directed = FALSE, node_attrs = NULL) {
  check_pkg("igraph")
  g <- igraph::graph_from_data_frame(edges, directed = directed)
  if (!is.null(node_attrs)) {
    igraph::vertex_attr(g) <- as.list(node_attrs[
      match(igraph::V(g)$name, node_attrs$id), , drop = FALSE])
  }
  g
}

# ---- build_cooccurrence_network -------------------------------------------
#' Build a weighted co-occurrence graph from a set of binary item columns.
#'
#' @param data    data.frame.
#' @param items  character vector of binary item column names.
#' @param min_coocurrence integer; minimum co-occurrence count to keep an edge.
build_cooccurrence_network <- function(data, items,
                                        min_cooccurrence = 1) {
  X <- as.matrix(data[, items, drop = FALSE])
  adj <- t(X) %*% X               # item x item co-occurrence
  diag(adj) <- 0
  edges <- which(adj >= min_cooccurrence, arr.ind = TRUE)
  edge_df <- data.frame(
    from   = colnames(adj)[edges[, 1]],
    to     = colnames(adj)[edges[, 2]],
    weight = adj[edges]
  )
  edge_df <- edge_df[edge_df$from < edge_df$to, ]  # undirected, drop dups
  make_graph(edge_df, directed = FALSE)
}

# ---- network_metrics -------------------------------------------------------
#' Return a one-row summary of graph structure.
network_metrics <- function(g) {
  check_pkg("igraph")
  data.frame(
    nodes       = igraph::vcount(g),
    edges       = igraph::ecount(g),
    density     = round(igraph::edge_density(g), 4),
    components  = igraph::components(g)$no,
    transitivity = round(igraph::transitivity(g), 4),
    mean_degree = round(mean(igraph::degree(g)), 2)
  )
}

# ---- add_centrality --------------------------------------------------------
#' Attach requested centrality scores as vertex attributes.
#'
#' @param g        igraph object.
#' @param measures character vector: subset of c("degree","betweenness","eigen").
add_centrality <- function(g, measures = c("degree", "betweenness", "eigen")) {
  check_pkg("igraph")
  if ("degree" %in% measures)
    igraph::V(g)$degree      <- igraph::degree(g)
  if ("betweenness" %in% measures)
    igraph::V(g)$betweenness <- igraph::betweenness(g, normalized = TRUE)
  if ("eigen" %in% measures)
    igraph::V(g)$eigen       <- igraph::eigen_centrality(g)$vector
  g
}

# ---- detect_communities ----------------------------------------------------
#' Detect communities and attach membership as a vertex attribute.
#'
#' @param g         igraph object.
#' @param algorithm "louvain", "leiden", "fast_greedy", "walktrap".
detect_communities <- function(g, algorithm = "louvain") {
  check_pkg("igraph")
  fn <- switch(algorithm,
    louvain      = igraph::cluster_louvain,
    leiden       = igraph::cluster_leiden,
    fast_greedy  = igraph::cluster_fast_greedy,
    walktrap     = igraph::cluster_walktrap,
    stop("Unknown algorithm: ", algorithm))
  com <- fn(g)
  igraph::V(g)$community <- igraph::membership(com)
  g
}

# ---- plot_network ----------------------------------------------------------
#' Render a publication network figure with ggraph.
#'
#' @param g        igraph object with `community` and a size attribute.
#' @param by       vertex attribute to color by ("community" or "class").
#' @param size_by  vertex attribute to size nodes by (e.g. "degree").
#' @param out_path file path for the PNG.
plot_network <- function(g, by = "community", size_by = "degree",
                         out_path = here::here("outputs", "figures", "network.png")) {
  check_pkg("ggraph"); check_pkg("ggplot2")
  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
  grDevices::png(out_path, width = 1800, height = 1400, res = 200)
  p <- ggraph::ggraph(g, layout = "fr") +
    ggraph::geom_edge_link(ggplot2::aes(alpha = weight), show.legend = FALSE) +
    ggraph::geom_node_point(ggplot2::aes(color = .data[[by]],
                                         size  = .data[[size_by]])) +
    ggraph::geom_node_text(ggplot2::aes(label = name), repel = TRUE, size = 3) +
    ggraph::theme_graph()
  print(p)
  grDevices::dev.off()
  invisible(out_path)
}

# ---- as_tibble_vertex ------------------------------------------------------
#' Export vertex attributes as a data frame (one row per node).
as_tibble_vertex <- function(g) {
  check_pkg("igraph")
  df <- as.data.frame(igraph::vertex_attr(g))
  if (!"name" %in% names(df)) df$name <- igraph::V(g)$name
  df
}

# ---- check_pkg (shared) ----------------------------------------------------
check_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is not installed. Run renv::restore() or install.packages('", pkg, "').")
  }
}
