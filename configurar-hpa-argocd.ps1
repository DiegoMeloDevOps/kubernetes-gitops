# ============================================================
# Configuração do Argo CD para trabalhar com HPA
# Homolog + Prod
# ============================================================

$ErrorActionPreference = "Stop"

$applications = @(
    @{
        Name      = "kubernetes-gitops-homolog"
        Namespace = "gitops-homolog"
        Values    = "values-homog.yaml"
        File      = "k8s\kubernetes-gitops-homolog-application.yaml"
    },
    @{
        Name      = "kubernetes-gitops-prod"
        Namespace = "gitops-prod"
        Values    = "values-prod.yaml"
        File      = "k8s\kubernetes-gitops-prod-application.yaml"
    }
)

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Configurando Argo CD + HPA" -ForegroundColor Cyan
Write-Host " Homolog + Prod" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($app in $applications) {

    Write-Host "Processando: $($app.Name)" -ForegroundColor Yellow

    $yaml = @"
apiVersion: argoproj.io/v1alpha1
kind: Application

metadata:
  name: $($app.Name)
  namespace: argocd

spec:
  project: default

  source:
    repoURL: https://github.com/DiegoMeloDevOps/kubernetes-gitops.git
    targetRevision: main
    path: helm/kubernetes-gitops-api
    helm:
      valueFiles:
        - $($app.Values)

  destination:
    server: https://kubernetes.default.svc
    namespace: $($app.Namespace)

  ignoreDifferences:
    - group: apps
      kind: Deployment
      name: kubernetes-gitops-api
      namespace: $($app.Namespace)
      jsonPointers:
        - /spec/replicas

  syncPolicy:
    automated:
      prune: true
      selfHeal: true

    syncOptions:
      - RespectIgnoreDifferences=true
"@

    # Criar/atualizar manifesto
    $yaml | Set-Content -Path $app.File -Encoding UTF8

    Write-Host "  Manifesto criado: $($app.File)" -ForegroundColor Green

    # Aplicar no cluster
    kubectl apply -f $app.File

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao aplicar $($app.Name)"
    }

    Write-Host "  Application aplicada com sucesso." -ForegroundColor Green
    Write-Host ""
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Verificando Applications" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

kubectl get applications -n argocd

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Verificando HPA" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

kubectl get hpa -n gitops-homolog
kubectl get hpa -n gitops-prod

Write-Host ""
Write-Host "Processo concluido." -ForegroundColor Green