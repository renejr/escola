-- Como suas tabelas já existem e utilizam UUID, vamos apenas fazer os inserts corretos.
-- Inserir Escola de Teste
INSERT INTO escolas (nome) VALUES ('Escola Modelo Alpha');

-- Inserir Usuário Admin (Adicionado o campo "nome")
INSERT INTO usuarios (escola_id, nome, email, senha_hash, papel) 
VALUES (
    (SELECT id FROM escolas WHERE nome = 'Escola Modelo Alpha' LIMIT 1), 
    'Administrador',
    'admin@escolaalpha.com.br', 
    '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 
    'admin'
);
