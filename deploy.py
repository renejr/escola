import os
import tarfile
import paramiko

def filter_backend(tarinfo):
    # Normaliza o caminho e separa as pastas para garantir a exclusão exata
    parts = tarinfo.name.replace('\\', '/').split('/')
    if 'venv' in parts or '__pycache__' in parts or '.git' in parts:
        return None
    if tarinfo.name.endswith('.env'):
        return None
    return tarinfo

def compress_files():
    print("\n[1/2] Compactando arquivos do backend...")
    
    print("      Criando backend_escola.tar.gz...")
    with tarfile.open("backend_escola.tar.gz", "w:gz") as tar:
        for item in ["gateway_service", "auth_service", "core_service", "docker-compose.yml"]:
            if os.path.exists(item):
                tar.add(item, filter=filter_backend)
            else:
                print(f"      Aviso: '{item}' não encontrado. Ignorando...")

def upload_and_deploy():
    print("\n[2/2] Enviando e descompactando na VPS (108.174.148.255:22022)...")
    hostname = "108.174.148.255"
    port = 22022
    username = "root"
    password = "@Energia12#"
    
    client = paramiko.SSHClient()
    # Aceita o fingerprint automaticamente
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy()) 
    
    try:
        print("      Estabelecendo conexão SSH...")
        client.connect(hostname, port=port, username=username, password=password)
        
        print("      Criando diretório de destino na VPS (se não existir)...")
        client.exec_command("mkdir -p /opt/saas_escola")
        
        sftp = client.open_sftp()
        
        print("      Enviando backend_escola.tar.gz...")
        sftp.put("backend_escola.tar.gz", "/opt/saas_escola/backend_escola.tar.gz")
        
        sftp.close()
        
        # Descompactação e Subida dos containers automatizada!
        print("      Descompactando arquivos na VPS...")
        stdin, stdout, stderr = client.exec_command("cd /opt/saas_escola && tar -xzvf backend_escola.tar.gz")
        exit_status = stdout.channel.recv_exit_status() # Aguarda a conclusão
        
        if exit_status == 0:
            print("      Arquivos descompactados com sucesso.")
            print("      Subindo serviços com docker-compose (build e detach)...")
            stdin, stdout, stderr = client.exec_command("cd /opt/saas_escola && docker-compose up -d --build")
            
            # Lê o output do docker-compose em tempo real
            for line in iter(stdout.readline, ""):
                print(f"      [DOCKER] {line.strip()}")
                
            docker_exit_status = stdout.channel.recv_exit_status()
            if docker_exit_status == 0:
                print("\nDeploy do Backend concluído e serviços iniciados com sucesso na VPS!")
            else:
                print(f"\nErro ao iniciar os containers:\n{stderr.read().decode('utf-8')}")
        else:
            print(f"\nErro ao descompactar os arquivos:\n{stderr.read().decode('utf-8')}")
            
    except Exception as e:
        print(f"Erro durante o deploy: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    print("Iniciando processo de deploy automático do Backend via Python...")
    compress_files()
    upload_and_deploy()
