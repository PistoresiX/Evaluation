-- Evaluations SQL avancé

-- Programmer des vues 

-- Création de la vue et du drop si cette vue et déjà existante

DROP VIEW IF EXISTS v_gescom_catalogue; 
CREATE VIEW v_gescom_catalogue
AS SELECT `pro_id`, `pro_ref` , `pro_name`, `cat_id` ,`cat_name`
from `products`
join `categories` on `cat_id` = `pro_cat_id`;

-- Programmer des procédures stockées

DELIMITER |

DROP PROCEDURE IF EXISTS facture|   

CREATE PROCEDURE facture
(
   in `p_Num_Com`    int(10)
)

BEGIN
    
    DECLARE `Num_Com_verif`   varchar(50);
 
    SET `Num_Com_verif` = (
        SELECT `ord_id`
        FROM `orders`
        WHERE `ord_id` = `p_Num_Com`
    );

    IF ISNULL(`Num_Com_verif`)

    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Ce numéro de commande n'existe pas";
    ELSE

        SELECT  commande.ord_id AS 'Numéro de commande',
                commande.ord_order_date AS 'Datée du',
                CONCAT(commande.cus_firstname, ' ', commande.cus_lastname, ' à ', commande.cus_city) AS 'Client',
                produits.ode_id AS 'Ligne de commande',
                CONCAT(produits.pro_ref, ' - ', produits.pro_name, ' - ', produits.pro_color) AS 'Produit',
                produits.ode_quantity AS 'Quantité produit',
                CONCAT(ROUND(produits.ode_unit_price, 2), '€') AS 'Prix unitaire',
                CONCAT(produits.ode_discount, '%') AS 'Remise',
                CONCAT(ROUND(totcom.total, 2), '€') AS 'Total'
        FROM (
            SELECT * FROM `orders`
            INNER JOIN `customers` ON `ord_cus_id` = `cus_id`
            WHERE `ord_id` = `p_Num_Com`
        ) commande,

        (
            SELECT * FROM `orders`
            INNER JOIN `orders_details` ON `ord_id` = `ode_ord_id`
            INNER JOIN `products` ON `ode_pro_id` = `pro_id`
            WHERE `ord_id` = `p_Num_Com`
        ) produits,

        (
            SELECT SUM((`ode_quantity` * `ode_unit_price`) * ((100-`ode_discount`)/100)) AS 'total'
            FROM `orders`
            INNER JOIN `orders_details` ON `ord_id` = `ode_ord_id`
            WHERE `ord_id` = `p_Num_Com`
        ) totcom;

    END IF;
END |

DELIMITER ;

-- Programmer des triggers


drop table if EXISTS commander_articles;
CREATE table commander_articles (
        `codart`  int (10),
        `qte` int (20),
        `date`  date not null,
    constraint commander_articles_codart_FK foreign KEY (codart) references products(pro_id),
    constraint commander_articles_PK PRIMARY KEY (codart)
);


DELIMITER |

DROP TRIGGER if EXISTS after_products_update |

CREATE TRIGGER after_products_update
after update 
on `products`
FOR EACH ROW


BEGIN
    DECLARE `new_qte` int(20);
    DECLARE `id_prod` int(10);
    DECLARE `prod_alert` int(10);
    DECLARE `prod_stock` int(10);
    DECLARE `verif` varchar(50);
    SET `prod_stock` = NEW.pro_stock;
    SET `prod_alert` = NEW.pro_stock_alert;
    SET `id_prod` = NEW.pro_id;



    if (`prod_stock`<`prod_alert`)
THEN

    SET `new_qte` = `prod_alert` - `prod_stock`;

    SET `verif` = (
        SELECT `codart`
        FROM `commander_articles`
        WHERE `codart` = `id_prod`
    );
    IF ISNULL(`verif`)

        THEN
            insert into commander_articles
            (`codart`, `qte`, `date`)
            values
            (id_prod, new_qte, CURRENT_DATE());
        ELSE
            update commander_articles
            SET `qte` = new_qte , 
                `date` = CURRENT_DATE()
            WHERE `codart` = `id_prod`;
        END IF ;
    ELSE 
        delete
        from commander_articles
        WHERE `codart` = `id_prod`;

    END IF;
END | 
DELIMITER ;

-- Maintenant les differents test demander avec le stock alert de 5 pour de le début 

-- Stock produit 5

SELECT * FROM commander_articles;

update products 
SET pro_stock = 5
WHERE pro_id = 8;

-- Stock produit 6

SELECT * FROM commander_articles;

update products 
SET pro_stock = 6
WHERE pro_id = 8;

-- Stock produit 4 

SELECT * FROM commander_articles;

update products 
SET pro_stock = 4
WHERE pro_id = 8;

-- Stock produit 3

SELECT * FROM commander_articles;

update products 
SET pro_stock = 3
WHERE pro_id = 8;


