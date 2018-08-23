-- author : zhang ning
-- date : 2018-08-23

begin
	declare v_consume_flag int default 0;
	declare v_flag int default 0;
	declare v_vegid int  default 0;
	declare v_batch_id char(6);
	declare v_in_date varchar(10);
	declare v_max_in_date varchar(10);
	declare v_datediff int;
	declare v_meat_batch_id varchar(32);
	declare v_vege_batch_id varchar(32);
	declare v_goods_code varchar(32);
	declare v_goods_name varchar(32);
	declare v_classifyResult varchar(32);
	declare v_retailer_id varchar(20);
	declare v_retailer_name varchar(128);
	declare v_busiNo varchar(20);
	declare v_ip varchar(32);
	declare v_sale_type int;
	declare v_num int;
	declare v_type int;
	declare v_length int;
	declare v_id int;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	insert into error_info(tb_name,tb_id,dt) values('XXXXX',v_id,now());

	set v_id=new.id;
	select date_format(new.insertDateTime,'%Y-%m-%d'),'330200' into v_in_date,@city_code;
	select 
		 b.marketID
		,b.marketName
		,a.busiInfoID
		,a.busiName
		,a.busiNo
		,ifnull(c.Ip,'-1')
		into @retail_id,@retail_name,v_retailer_id,v_retailer_name,v_busiNo,v_ip
		from busiinfo a 
			left join market b 
					on a.marketId = b.marketID
			left join ecrinfo c 
					on a.busiInfoID = c.busiId
		where c.ecrID=new.uploadDevice;

	set v_classifyResult=new.goodsCode;

	select count(*) into v_num from goodsinfo where name=new.goodsCode;
	if v_num>=1 then
		select min(goodsid) into v_goods_code from goodsinfo where name=new.goodsCode;
	elseif v_num=0 then
		if exists(select 1 from ecrinfo where ecrtype=v_classifyResult) then
				set v_goods_code='0';
		else 
				set v_goods_code= null;
		end if;
	end if;
        
	if v_classifyResult='猪肉' then
		set v_goods_code = '21113011';
	end if;

	if v_classifyResult='' then
     set v_goods_code=null;
  end if;
 
  
	if v_goods_code is not null then
		if v_classifyResult='猪肉' or v_classifyResult in (select a.name
						from goodsinfo a 
								left join maincategory b
								on a.mainID=b.mainid
								where b.name='肉类' and a.pinyinTag is not null) then
				set v_type=1;
				set v_length=20;
		elseif v_classifyResult in (select a.name
							from goodsinfo a 
									left join maincategory b
									on a.mainID=b.mainid
									where b.name='蔬菜' and a.pinyinTag is not null) then
				set v_type=0;
				set v_length=16;
		else
				set v_type=1;
				set v_length=20;
		end if; 

		if v_goods_code='0' then
				set v_consume_flag=1;
				if not exists(select 1 from gy_retail_market_in_info where retailer_id=v_retailer_id /*and goods_name=v_classifyResult*/ and sale_type=1 and in_date=v_in_date
/*
					and (length(vege_batch_id)=v_length or length(meat_batch_id)=v_length)
					and (vege_batch_id like '100%' or meat_batch_id like '100%')
*/
				) then
						set v_flag=1;
				else
					if not exists(select 1 from gy_retail_market_in_info where retailer_id=v_retailer_id and goods_name=v_classifyResult and sale_type=1 and in_date=v_in_date
/*
						and (length(vege_batch_id)=v_length or length(meat_batch_id)=v_length)
						and (vege_batch_id like '100%' or meat_batch_id like '100%')
*/
					) then
						set v_flag=2;
					end if;

					select meat_batch_id,vege_batch_id,sale_type,v_classifyResult into v_meat_batch_id,v_vege_batch_id,v_sale_type,v_goods_name 
					from gy_retail_market_in_info 
					where retailer_id=v_retailer_id and sale_type=1 and in_date=v_in_date /*and goods_name=v_classifyResult and (vege_batch_id like '100%' or meat_batch_id like '100%')*/ limit 1;
					-- group by meat_batch_id,vege_batch_id,sale_type;	
				end if;
		else
				set v_consume_flag=1;
				select max(in_date) into v_max_in_date from gy_retail_market_in_info where retailer_id=v_retailer_id and goods_code=v_goods_code and sale_type=0;
				select datediff(v_in_date,v_max_in_date) into v_datediff;
				if v_datediff >= 0 and v_datediff <= 2 then
						select min(veg_id) into v_vegid from gy_retail_market_in_info where retailer_id=v_retailer_id /*and goods_code=v_goods_code*/ and in_date=v_max_in_date and sale_type=0 and (length(vege_batch_id)=20 or length(meat_batch_id)=20);
						if v_vegid is null then
							select min(veg_id) into v_vegid from gy_retail_market_in_info where retailer_id=v_retailer_id /*and goods_code=v_goods_code*/ and in_date=v_max_in_date and sale_type=0 and (length(vege_batch_id)=16 or length(meat_batch_id)=16);
						end if;
						
						if v_vegid is not null then
							select meat_batch_id,vege_batch_id,sale_type,goods_name into v_meat_batch_id,v_vege_batch_id,v_sale_type,v_goods_name from gy_retail_market_in_info where veg_id=v_vegid;							
						else
							set v_flag=1;
						end if;	
				else
						if not exists(select 1 from gy_retail_market_in_info where retailer_id=v_retailer_id /*and goods_code=v_goods_code*/ and in_date=v_in_date and sale_type=1
/*
							and (length(vege_batch_id)=v_length or length(meat_batch_id)=v_length)
							and (vege_batch_id like '100%' or meat_batch_id like '100%')
*/	
					) then
							set v_flag=1;
						else
							if not exists(select 1 from gy_retail_market_in_info where retailer_id=v_retailer_id and goods_code=v_goods_code and in_date=v_in_date and sale_type=1
/*	
								and (length(vege_batch_id)=v_length or length(meat_batch_id)=v_length)
								and (vege_batch_id like '100%' or meat_batch_id like '100%')
*/
							) then
								set v_flag=2;
							end if;

							select meat_batch_id,vege_batch_id,sale_type,v_classifyResult into v_meat_batch_id,v_vege_batch_id,v_sale_type,v_goods_name 
							from gy_retail_market_in_info 
							where retailer_id=v_retailer_id and in_date=v_in_date and sale_type=1 /*and goods_code=v_goods_code and (vege_batch_id like '100%' or meat_batch_id like '100%')*/ limit 1;
							-- group by meat_batch_id,vege_batch_id,sale_type;
						end if;
				end if;
		end if;
		
		if v_flag in (1,2) then
			-- select lpad(batch_id,6,'0') into v_batch_id from gy_retail_market_batch_id;
			/*
			if v_classifyResult='猪肉' or v_classifyResult in (select a.name
							from goodsinfo a 
									left join maincategory b
									on a.mainID=b.mainid
									where b.name='肉类' and a.pinyinTag is not null) then
			*/
			if v_flag ='1' then
					if v_type = '1' then
						set v_vege_batch_id = '';
						select cast(10000000000000000000+batch_id as char) into v_meat_batch_id from gy_retail_market_batch_id;
						-- set v_meat_batch_id = concat(v_retailer_id,'9',v_batch_id);
					elseif v_type = '0' then
						-- set v_vege_batch_id = concat(v_retailer_id,'9',v_batch_id);
						select cast(1000000000000000+batch_id as char) into v_vege_batch_id from gy_retail_market_batch_id;
						set v_meat_batch_id = '';
				end if;
				
				update gy_retail_market_batch_id set batch_id=batch_id+1,last_update_time=now();
			end if;

			set v_goods_name = v_classifyResult;
			set v_sale_type = 1;
			insert into gy_retail_market_in_info(
					id,city_code,retail_id,retail_name,in_date,in_time,retailer_id,retailer_name,meat_batch_id,vege_batch_id,voucher_type,goods_code,goods_name,weight,price,area_origin_id,area_origin_name,update_time2,dt,update_time,pf_num_id,sale_type,goods_photo,settlement_num,rec_goods_name,booth_num,electronic_id,serial_num)
			values(1,@city_code,@retail_id,@retail_name,v_in_date,'IN_TIME',v_retailer_id,v_retailer_name,v_meat_batch_id,v_vege_batch_id,'0',v_goods_code,v_goods_name,100,0,'330212','浙江省宁波市鄞州区',DATE_FORMAT(now(),'%Y-%m-%d %T:%f'),now(),now(),'0',v_sale_type,'GOODS_PHOTO','SETTLEMENT_NUM','REC_GOODS_NAME','BOOTH_NUM','ELECTRONIC_ID','SERIAL_NUM');
		end if;

		if v_consume_flag = 1 then
			insert into gy_retail_market_tran_summ(
			 id
			,city_code
			,retail_id
			,retail_name
			,in_date
			,sale_date
			,retailer_id
			,retailer_name
			,position_code
			,meat_batch_id
			,vege_batch_id
			,goods_code
			,goods_name
			,weight
			,price
			,sale_tran_id
			,last_trace_code
			,rec_goods_name
			,in_time
			,booth_num
			,electronic_id
			,goods_photo
			,serial_num
			,settlement_num
			,update_time2
			,err
			,dt
			,update_time
			,sale_type
			)
			values(
				 '1'
				,@city_code
				,@retail_id
				,@retail_name
				,v_in_date
				,v_in_date
				,v_retailer_id
				,v_retailer_name
				,v_busiNo
				,v_meat_batch_id
				,v_vege_batch_id
				,v_goods_code
				,v_goods_name
				,new.wight/1000 
				,new.price/100
				,new.traceCode
				,''
				,v_classifyResult
				,'IN_TIME'
				,v_busiNo
				,v_ip
				,new.picName
				,new.billId
				,new.uploadDevice
				,new.insertDateTime
				,'ERR'
				,now()
				,new.insertDateTime
				,v_sale_type
				);
		end if;
	end if;
end;