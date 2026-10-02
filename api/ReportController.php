<?php
declare(strict_types=1);

final class ReportController
{
    public static function dashboard(): never
    {
        [$from,$to]=self::range(true);$pdo=Database::connection();$summary=self::summary($pdo,$from,$to);
        $active=$pdo->query("SELECT id,service_number,customer_name,customer_whatsapp,device_name,service_name,service_status,payment_status,total_paid,remaining_payment,received_at FROM services WHERE deleted_at IS NULL AND service_status IN ('waiting','working') ORDER BY received_at ASC LIMIT 50")->fetchAll();
        $low=$pdo->query('SELECT id,name,category,stock_quantity,minimum_stock,unit FROM products WHERE deleted_at IS NULL AND is_active=1 AND track_stock=1 AND stock_quantity<=minimum_stock ORDER BY stock_quantity ASC,name ASC LIMIT 50')->fetchAll();
        $recent=self::recent($pdo);$chart=self::chart($pdo,$from,$to);
        Response::success(['period'=>['from'=>$from,'to'=>$to],'summary'=>$summary,'active_services'=>$active,'low_stock'=>$low,'recent_transactions'=>$recent,'sales_chart'=>$chart]);
    }

    public static function overall(): never
    {[$f,$t]=self::range(false);Response::success(['period'=>['from'=>$f,'to'=>$t],'summary'=>self::summary(Database::connection(),$f,$t)]);}

    public static function products(): never
    {[$f,$t]=self::range(false);$sql='SELECT si.product_id,si.product_name,SUM(si.quantity) quantity_sold,SUM(si.line_total) omzet,SUM(si.line_cost) modal,SUM(si.line_profit) profit FROM sale_items si INNER JOIN sales s ON s.id=si.sale_id WHERE si.deleted_at IS NULL AND s.deleted_at IS NULL AND s.sold_at BETWEEN :f AND :t GROUP BY si.product_id,si.product_name ORDER BY omzet DESC';Response::success(['period'=>['from'=>$f,'to'=>$t],'items'=>self::rows($sql,['f'=>$f,'t'=>$t])]);}

    public static function services(): never
    {[$f,$t]=self::range(false);$sql="SELECT device_name,service_name,COUNT(*) transaction_count,SUM(service_price) omzet,SUM(total_cost) modal,SUM(profit) profit FROM services WHERE deleted_at IS NULL AND service_status='completed' AND completed_at BETWEEN :f AND :t GROUP BY device_name,service_name ORDER BY omzet DESC";Response::success(['period'=>['from'=>$f,'to'=>$t],'items'=>self::rows($sql,['f'=>$f,'t'=>$t])]);}

    public static function phones(): never
    {[$f,$t]=self::range(false);$sql="SELECT device_name,acquisition_type,COUNT(*) transaction_count,SUM(selling_price) omzet,SUM(purchase_price) modal,SUM(profit) profit FROM phones WHERE deleted_at IS NULL AND phone_status='sold' AND sale_date BETWEEN :f AND :t GROUP BY device_name,acquisition_type ORDER BY omzet DESC";Response::success(['period'=>['from'=>$f,'to'=>$t],'items'=>self::rows($sql,['f'=>$f,'t'=>$t])]);}

    public static function expenses(): never
    {[$f,$t]=self::range(false);$sql='SELECT id,expense_name,amount,expense_date,notes FROM expenses WHERE deleted_at IS NULL AND expense_date BETWEEN :f AND :t ORDER BY expense_date DESC';$items=self::rows($sql,['f'=>$f,'t'=>$t]);$total=array_sum(array_map(fn($r)=>(float)$r['amount'],$items));Response::success(['period'=>['from'=>$f,'to'=>$t],'total'=>number_format($total,2,'.',''),'items'=>$items]);}

    public static function payments(): never
    {
        [$f,$t]=self::range(false);$sql="SELECT payment_method,SUM(amount) total FROM (SELECT payment_method,total_amount amount FROM sales WHERE deleted_at IS NULL AND sold_at BETWEEN :f1 AND :t1 UNION ALL SELECT payment_method,amount FROM service_payments WHERE deleted_at IS NULL AND paid_at BETWEEN :f2 AND :t2 UNION ALL SELECT payment_method,selling_price amount FROM phones WHERE deleted_at IS NULL AND phone_status='sold' AND sale_date BETWEEN :f3 AND :t3) x GROUP BY payment_method ORDER BY total DESC";
        $p=['f1'=>$f,'t1'=>$t,'f2'=>$f,'t2'=>$t,'f3'=>$f,'t3'=>$t];Response::success(['period'=>['from'=>$f,'to'=>$t],'items'=>self::rows($sql,$p)]);
    }

    private static function summary(PDO $pdo,string $f,string $t): array
    {
        $sales=self::one($pdo,'SELECT COALESCE(SUM(total_amount),0) omzet,COALESCE(SUM(total_profit),0) profit,COUNT(*) transactions FROM sales WHERE deleted_at IS NULL AND sold_at BETWEEN :f AND :t',$f,$t);
        $services=self::one($pdo,"SELECT COALESCE(SUM(service_price),0) omzet,COALESCE(SUM(profit),0) profit,COUNT(*) transactions FROM services WHERE deleted_at IS NULL AND service_status='completed' AND completed_at BETWEEN :f AND :t",$f,$t);
        $phones=self::one($pdo,"SELECT COALESCE(SUM(selling_price),0) omzet,COALESCE(SUM(profit),0) profit,COUNT(*) transactions FROM phones WHERE deleted_at IS NULL AND phone_status='sold' AND sale_date BETWEEN :f AND :t",$f,$t);
        $expenses=self::one($pdo,'SELECT COALESCE(SUM(amount),0) amount,COUNT(*) transactions FROM expenses WHERE deleted_at IS NULL AND expense_date BETWEEN :f AND :t',$f,$t);
        $revenue=(float)$sales['omzet']+(float)$services['omzet']+(float)$phones['omzet'];$profit=(float)$sales['profit']+(float)$services['profit']+(float)$phones['profit'];$expense=(float)$expenses['amount'];
        return['omzet'=>self::money($revenue),'gross_profit'=>self::money($profit),'expenses'=>self::money($expense),'net_profit'=>self::money($profit-$expense),'transactions'=>(int)$sales['transactions']+(int)$services['transactions']+(int)$phones['transactions'],'breakdown'=>['products'=>$sales,'services'=>$services,'phones'=>$phones,'expenses'=>$expenses]];
    }

    private static function recent(PDO $pdo): array
    {
        $sql="SELECT * FROM (SELECT 'product_sale' type,id reference_id,transaction_number title,total_amount amount,sold_at occurred_at FROM sales WHERE deleted_at IS NULL UNION ALL SELECT 'service' type,id reference_id,CONCAT(device_name,' - ',service_name) title,service_price amount,received_at occurred_at FROM services WHERE deleted_at IS NULL UNION ALL SELECT 'phone_sale' type,id reference_id,device_name title,selling_price amount,sale_date occurred_at FROM phones WHERE deleted_at IS NULL AND phone_status='sold' UNION ALL SELECT 'expense' type,id reference_id,expense_name title,-amount amount,expense_date occurred_at FROM expenses WHERE deleted_at IS NULL) x ORDER BY occurred_at DESC LIMIT 20";
        return $pdo->query($sql)->fetchAll();
    }

    private static function chart(PDO $pdo,string $f,string $t): array
    {
        $sql="SELECT day,SUM(omzet) omzet FROM (SELECT DATE(sold_at) day,total_amount omzet FROM sales WHERE deleted_at IS NULL AND sold_at BETWEEN :f1 AND :t1 UNION ALL SELECT DATE(completed_at) day,service_price omzet FROM services WHERE deleted_at IS NULL AND service_status='completed' AND completed_at BETWEEN :f2 AND :t2 UNION ALL SELECT DATE(sale_date) day,selling_price omzet FROM phones WHERE deleted_at IS NULL AND phone_status='sold' AND sale_date BETWEEN :f3 AND :t3) x GROUP BY day ORDER BY day";
        $s=$pdo->prepare($sql);$s->execute(['f1'=>$f,'t1'=>$t,'f2'=>$f,'t2'=>$t,'f3'=>$f,'t3'=>$t]);return$s->fetchAll();
    }

    private static function one(PDO $pdo,string $sql,string $f,string $t): array{$s=$pdo->prepare($sql);$s->execute(['f'=>$f,'t'=>$t]);return$s->fetch();}
    private static function rows(string $sql,array $p): array{$s=Database::connection()->prepare($sql);$s->execute($p);return$s->fetchAll();}
    private static function money(float $v): string{return number_format($v,2,'.','');}

    private static function range(bool $todayDefault): array
    {
        $from=trim((string)($_GET['from']??''));$to=trim((string)($_GET['to']??''));
        if($from===''&&$to===''){if($todayDefault){$day=gmdate('Y-m-d');return[$day.' 00:00:00',$day.' 23:59:59'];}return['2000-01-01 00:00:00','2999-12-31 23:59:59'];}
        if($from==='')$from='2000-01-01';if($to==='')$to='2999-12-31';
        try{$fd=new DateTimeImmutable($from,new DateTimeZone('UTC'));$td=new DateTimeImmutable($to,new DateTimeZone('UTC'));}catch(Throwable){Response::error('Rentang tanggal tidak valid.',422);}
        $f=preg_match('/^\d{4}-\d{2}-\d{2}$/',$from)===1?$fd->format('Y-m-d').' 00:00:00':$fd->format('Y-m-d H:i:s');$t=preg_match('/^\d{4}-\d{2}-\d{2}$/',$to)===1?$td->format('Y-m-d').' 23:59:59':$td->format('Y-m-d H:i:s');
        if($f>$t)Response::error('Tanggal awal tidak boleh melewati tanggal akhir.',422);return[$f,$t];
    }
}
