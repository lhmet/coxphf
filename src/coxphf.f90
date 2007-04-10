SUBROUTINE FIRTHCOX(cards, parms, IOARRAY)
!DEC$ ATTRIBUTES DLLEXPORT :: firthcox
IMPLICIT DOUBLE PRECISION (A-H,O-Z)  


real*8, dimension (14) :: parms
integer N, IP,JCODE,IFIRTH,ISEP,ITER,IMAXIT,IMAXHS
real*8, dimension (int(parms(1))) :: BX, T1, t2, TMSF
real*8, dimension (int(parms(1)),int(parms(2))) :: X, XMSF, bresx
real*8, dimension (int(parms(2)+parms(14))) :: B, B0, FD, OFFSET,STDERR,BMSF,zw1, xx, yy 
real*8, dimension (int(parms(2)+parms(14)),int(parms(2)+parms(14))) :: SD, VM, WK
integer, dimension (int(parms(1))) :: ibresc, IC, ICMSF
integer, dimension (int(parms(2)+parms(14))) :: IFLAG
real*8, dimension (int(parms(1)),int((2*parms(2)+3+2*(parms(14))))) :: cards
real*8, dimension (int((3+parms(2)+parms(14))),int((parms(2)+parms(14)))) :: IOARRAY
real*8, dimension (14) :: DER, EREST
logical, dimension (int(parms(2)+parms(14)),int(parms(2)+parms(14))) :: mask
real*8, dimension (int(parms(1)),int(parms(14)+1)) :: ft
integer ngv, ntde
integer, dimension (int(parms(14)+1)) :: ftmap
real*8, dimension (int(parms(1)), int(parms(14)+parms(2))) :: score_weights

INTRINSIC DABS, DSQRT               

!open(unit=6, file="fgcssan.txt")

! ntde = parms(14)
              
N=parms(1)
IP=parms(2)
IFIRTH=parms(3)
imaxit=Parms(4)
imaxhs=parms(5)
step=parms(6)
crili=parms(7)

ngv=parms(13)
ntde=parms(14)

parms(10)=-11

offset=ioarray(2,:)
iflag=ioarray(1,:)

t1=cards(:,ip+1)
t2=cards(:,ip+2)
ic=cards(:,ip+3)
score_weights=cards(:,(ip+4):(2*ip+3+ntde))

x=cards(:,1:ip)
if (ntde .gt. 0) then 
! do j=1,ntde
!  ftmap(j)=ioarray(4,ip+j)
!  write(6,*) ftmap(j)
!  do i=1,n
!   ft(i,j)=cards(i,(2*ip+3+ntde+j))
!   write(6,*) ft(i,j)
!  end do
  ft(:,1:ntde)=cards(:,(2*ip+3+ntde+1):(2*ip+3+ntde*2))
  ftmap(:)=ioarray(4,ip+1:ip+ntde)
!  end do
else
 ft=0
 ftmap=0
end if

bresx=x
ibresc=ic


do i=n-1,1,-1
 if (ic(i+1)-1 .gt. -0.0001) then
  if (dabs(t2(i)-t2(i+1)) .lt. 0.0001) then
   score_weights(i,:)=score_weights(i+1,:)
   bresx(i,:)=bresx(i,:)+bresx(i+1,:)
   ibresc(i)=ibresc(i)+ibresc(i+1)
   ibresc(i+1)=0
  end if
 end if
end do

mask=.FALSE.
do j=1,Ip+ntde
 mask(j,j)=.TRUE.
end do

isep=0
XL=0.
xl0=xl-2*crili

b0=0.

where(iflag .eq. 0)
 b0=offset
elsewhere(iflag .eq. 2)
 b0=offset
 iflag=1
endwhere

isflag=sum(iflag)
!write(6,*) "ISFLAG", isflag
b(:)=b0(:)

ITER=0
iconv=0
JCODE=0



!do while((isflag .gt. 0) .and.  ((iter .gt. 1) .and. (dabs(xl0-xl) .gt. crili)) .and. (iter .lt. imaxit))
do while((iconv .eq. 0) .and. (iter .lt. imaxit))
! write(6,*) iter, b
 iter=iter+1
 b0(:)=b(:)
 XL0=XL
 parms(10)=-10
! write(6,*) "Vor 1. LIKE", b
 if (iter .eq. 1) then
  CALL LIKE(N,IP,X,T1,t2,IC,XL,FD,SD,B,JCODE,IFIRTH,ngv,score_weights,bresx,ibresc,ntde,ft,ftmap)
 end if
! write(6,*) "Nach 1. LIKE"

 parms(10)=-9
 parms(8)= real (JCODE)
 IF (JCODE .GE. 1) RETURN
 IFAIL=0
 wk=-sd
 EPS=.000000000001D0
 CALL INVERT(WK,IP+ntde,IP+ntde,VM,IP+ntde,EPS,IFAIL)                             
 IF(ITER.EQ.1) then
  parms(12)=xl
  zw=0.
  zw1=matmul(vm, fd)
  zw=dot_product(fd,zw1)
  parms(7)=zw
 end if
 parms(11)=xl
 parms(10)=iter
 parms(9)=isep
 If (ISFLAG.ne.0) then
  IF(IFAIL.ne.0) then
!   "Save" Variance matrix if INVERT failed
 !  WRITE(6,*) 'Inversion failed', ITER,IFIRTH
   ICONV=0
   JCODE=3
   return
  else  
   DO I=1,(IP+ntde)                                                      
    IF (IFLAG(I).EQ.1) then 
     TT=dot_product(vm(I,:),fd(:)*iflag(:))
     IF (DABS(TT).GT.STEP) TT=TT/DABS(TT)*STEP
     B(I)=B(I)+TT
    end if
   end do
!   half step if new log-likelihood is less than old one
   ICONV=0
   IHS=0
   CALL LIKE(N,IP,X,T1,t2,IC,XL,FD,SD,B,JCODE,IFIRTH, ngv, score_weights,bresx,ibresc,ntde,ft,ftmap)
   do while(((XL .le. XL0) .AND. (ITER.ne.1)) .AND. (ihs .le. imaxhs) .and. ((ngv .EQ. IP+ntde) .OR. (ngv .EQ. 0))) 
    IHS=IHS+1
    where (iflag .eq. 1)
     b=(b+b0)/2
    end where
    CALL LIKE(N,IP,X,T1,t2,IC,XL,FD,SD,B,JCODE,IFIRTH, ngv, score_weights,bresx,ibresc,ntde,ft,ftmap)
   end do
  end if
 end if
 ICONV=1
 if (isflag .gt. 0) then
  XX=dabs(B-B0)                                                   
  IF(any(XX.GT.CRILI)) ICONV=0
 end if
end do




wk=-sd
EPS=.000000000001D0


CALL INVERT(WK,IP+ntde,IP+ntde,VM,IP+ntde,EPS,IFAIL)       


ioarray(3,:)=b(:)
ioarray(4:3+ip+ntde,:)=vm
!do j=1,(ip+ntde)
! ioarray(3,j)=b(j)
! do k=1,(ip+ntde)
!  ioarray(3+j,k)=vm(j,k)
! end do
!end do
!return

!stderr=dsqrt(pack(VM,mask))
!parms(10)=-8



yy=pack(sd,mask)
yy=dabs(yy)
if (any(yy .lt. 0.0001)) isep=1



zw=0.
zw1=matmul(vm, fd)
zw=dot_product(fd,zw1)
parms(9)=zw

parms(8)=jcode
parms(11)=xl
parms(10)=iter

!close(unit=6)

RETURN              

end


SUBROUTINE plusone(a)

real*8 a

a=a+1.

return
end



SUBROUTINE INVRT(A,IA)                          


!                                                                       
!...original matrix=a inverse matrix =a (on exit)                                 
!...note that a is changed on exit                                      
!                                                                       
 INTEGER IA,n
 real*8 eps                                             
 real*8, dimension (IA,ia) :: A, B, WK
 INTRINSIC DABS                                                    
                                                                       
 wk=a

 IFAIL=0
 b=a
 N=ia
 
 CALL vert(b, IA, N, WK)
 a=b
    
 RETURN
END  

SUBROUTINE INVERT(A,IA,N,B,IB,EPS,IFAIL)                          
!DEC$ ATTRIBUTES DLLEXPORT :: invert


!                                                                       
!...original matrix=a inverse matrix =b                                 
!...note that a is changed on exit                                      
!...eps is a small quantity used to see if matrix singular              
!...ifail on exit ifail=0 ok, ifail=1 matrix nearly singular            
!                                                                       
 INTEGER IA,N,ib,ifail
 real*8 eps                                             
 real*8, dimension (IA,N) :: A, B, WK
 INTRINSIC DABS                                                    
                                                                       
 wk=a

 IFAIL=0
 b=a

 CALL vert(b, IA, N, WK)

    
 RETURN
END  

function deter(ain, IA, n)

 INTEGER e, ia, n
 real*8, dimension (IA, N) :: AIN
 real*8, dimension(3+n*(n+1)) :: a
 call fact(ain, a, IA, N)
 deter=det(e,a,n)
 deter=deter*10**e

 return
end function deter


SUBROUTINE LIKE(N,IP,X,T1,t2,IC,XL,FD,SD,B,JCODE,IFIRTH, ngv, score_weights,bresx,ibresc, ntde,ft, ftmap) 
!DEC$ ATTRIBUTES DLLEXPORT :: like

 IMPLICIT DOUBLE PRECISION (A-H,O-Z)
 real*8, dimension (IP+ntde,IP+ntde) :: DINFO, DINFOI, SD, SDI, WK, help
 real*8, dimension (IP+ntde,IP+ntde,IP+ntde) :: dabl
 real*8 SEBX, zeitp
 real*8, dimension (IP+ntde) :: XEBX, bresxges
 real*8, dimension (IP+ntde,IP+ntde) :: XXEBX
! real*8, dimension (N+1, IP, Ip, IP) :: XXXEBX
 real*8, dimension (IP+ntde) :: FD, B, h1, h2, h3
 real*8, dimension (N) :: EBX, BX, T1, t2, WKS, hh0, hh1, hh2
 integer, dimension (N) :: IC,ibresc
 real*8, dimension (N,IP) :: X, bresx
 real*8, dimension (N, ip+ntde) :: xges, score_weights
 integer ngv, ntde
 logical, dimension (N) :: maske
 real*8, dimension (N,ntde+1) :: ft
 integer, dimension (ntde+1) :: ftmap

 intrinsic dexp 

 dlowest=0.000000001
! write(6,*) "in LIKE"
 XL=0.

 
 ipges=ip+ntde
                                        
 ! bx=matmul(x,b)
 ! ebx=dexp(bx)


 xl=0.
 fd(:)=0.
 sd(:,:)=0.
 dabl(:,:,:)=0.


! Likelihood (XL) is only correct if all or none of the variables is weighted


! do i=1,n
!  do j=1,ip
!   xges(i,j)=x(i,j)
!  end do
! end do
 xges(:,1:ip)=x

 do i=1,N
  if (ibresc(i) .ne. 0) then   
!   write(6,*) i
!   do i2=1,N
!    zeitp(i2)=t2(i)-0.00001
!   end do
   zeitp=t2(i)-0.00001
   where ((t1 .lt. zeitp) .and. (t2.ge. zeitp))
    maske=.true. 
   elsewhere
    maske=.false.
   end where
   bresxges(1:ip)=bresx(i,1:ip)
   if (ntde .gt. 0) then
    do j=(ip+1),(ip+ntde)
!    do i2=1,n
!     xges(i2,j)=x(i2,ftmap(j-ip))*ft(i,j-ip)
!    end do
     xges(:,j)=x(:,ftmap(j-ip))*spread(ft(i,j-ip),1,n)
     bresxges(j)=ft(i,j-ip)*bresx(i,ftmap(j-ip))
    end do
!   bresxges(ip+1:ip+ntde)=ft(i,1:ntde)*bresx(i,ftmap)
   end if
!   do i2=1,n
!    write(6,*) xges(i2,:)
!   end do
!   write(6,*) bresxges

   bx=matmul(xges,b)
   ebx=dexp(bx)
   sebx=sum(ebx,1,maske)
!   write(6,*) "B",b
!   write(6,*) "BX",bx
!   write(6,*) "EBX",ebx
!   write(6,*) "SEBX", sebx
   do j=1,ipges
    hh0=xges(:,j)*ebx
    xebx(j)=sum(hh0,1,maske)
!   write(6,*) "XEBX(",j,")",xebx(j)
    do k=1,ipges
     hh1=hh0*xges(:,k)
     xxebx(j,k)=sum(hh1,1,maske)
!    write(6,*) "XXEBX(",j,",",k,")", xxebx(j,k)
    end do
   end do

   if (sebx .gt. dlowest) then
    dlogsebx=dlog(sebx)
   else
    dlogsebx=dlog(dlowest)
   endif
    

   if (ngv .eq. ipges) then 
    XL=XL+(dot_product(bresxges,b)-ibresc(i)*DLOGSEBX)*score_weights(i,1)
   else
    XL=XL+(dot_product(bresxges,b)-ibresc(i)*DLOGSEBX)
   endif
   do j=1,ipges
    FD(J)=FD(J)+(bresXges(J)-ibresc(i)*XEBX(J)/SEBX)*score_weights(i,j)                           
    do k=1,ipges
     SD(J,K)=SD(J,K)-ibresc(i)*((xxebx(j,k)-XEBX(J)/SEBX*XEBX(K))/SEBX)*score_weights(i,j)*score_weights(i,k) 
     if (ifirth .ne. 0) then
      hh1=xges(:,k)*xges(:,j)*ebx
      DO L=1,IPges
       hh2=xges(:,l)*hh1
       DABL(j,k,l)=DABL(j,k,l)-ibresc(i)*((sum(hh2,1,maske)-xxEBX(k,l)*xEBX(j)/SEBx-xEBX(l)*(xxEBX(k,j)  &
        -xEBX(k)*xEBX(j)/SEBx)/SEBx-xEBX(k)*(xxEBX(l,j)-xEBX(l)*xEBX(j)/SEBx)/SEBx)/SEBx)*score_weights(i,j) &
        *score_weights(i,k)*score_weights(i,l)
      end do
     end if
    end do
   end do
  end if
 end do

                    
 
      
    
 if (IFIRTH .NE. 0) then 

  wk(:,:)=-sd(:,:)
  dinfo(:,:)=-sd(:,:)

  IFAIL=0
  CALL INVERT(WK,IPges,IPges,DINFOI,IPges,0.00000000001D0,IFAIL)

  DO J=1,IPges
   TRACE=0
   DO  K=1,IPges
    do l=1,IPges
     TRACE=TRACE-DINFOI(k,l)*DABL(j,l,k)
    end do
   end do
   fd(j)=fd(j)+trace/2
  end do

 
  DET=DINFO(1,1)
  IF(IPges .NE. 1) then 
   IDETFAIL=0
   DET=0.
   det=deter(DINFO,IPGES,IPGES)
!   CALL F03AAF(DINFO,IPges,IPges,DET,WKS,IDETFAIL)
   IF(IDETFAIL.NE.0) JCODE=2
   IF (DET.LT.1.E-30) DET=1.E-30
  end if
  XL=XL+0.5*dlog(DET)
 end if

 RETURN
END                                                               





SUBROUTINE PLCOMP(CARDS, PARMS, IOARRAY)
!DEC$ ATTRIBUTES DLLEXPORT :: plcomp

IMPLICIT DOUBLE PRECISION (A-H,O-Z)
INTRINSIC DABS, DSQRT, DSIGN                                                    
real*8, dimension (14) :: parms
real*8, dimension (int(parms(1))) :: T1,t2
real*8, dimension (int(parms(1)),int(parms(2))) :: X, bresx
integer, dimension (int(parms(1))) :: IC, ibresc
real*8, dimension (int(parms(2)+parms(14))) :: B, B0, FD, OFFSET, PVALUE, XE,DELTA,XGRAD, BSAVE, STDERR
real*8, dimension (int(parms(2)+parms(14)),int(parms(2)+parms(14))) :: SD, VM, WK, XHESS, XVM
real*8, dimension (int(parms(2)+parms(14)),2) :: CI
integer, dimension (int(parms(2)+parms(14))) :: IFLAG
real*8, dimension (int(parms(1)),int(2*parms(2)+2*parms(14)+3)) :: cards
real*8, dimension (8,int(parms(2)+parms(14))) :: IOARRAY
real*8, dimension (14) :: parmsfc
real*8, dimension (int(3+parms(2)+parms(14)),int(parms(2)+parms(14))) :: IOAFC
real*8, dimension (int(parms(1)),int(parms(14)+1)) :: ft
integer, dimension (int(parms(14)+1)) :: ftmap
real*8, dimension (int(parms(1)), int(parms(14)+parms(2))) :: score_weights

!open(unit=6, file="fgcsspl.txt")

N=parms(1)
IP=parms(2)
IFIRTH=parms(3)
imaxit=Parms(4)
imaxhs=parms(5)
step=parms(6)
crili=parms(7)
CHI=parms(8)
PARMS(9)=0     

ngv=parms(13)
ntde=parms(14)

offset(:)=ioarray(2,:)
iflag(:)=ioarray(1,:)
b(:)=ioarray(3,:)
b0(:)=ioarray(3,:)

!   do j=1,ip,1
!    offset(j)=IOARRAY(2,j)
!    iflag(j)=IOARRAY(1,j)
!    b(j)=IOARRAY(3,j)
!    b0(j)=IOARRAY(3,j)
!   end do

t1=cards(:,ip+1)
t2=cards(:,ip+2)
ic=cards(:,ip+3)


x=cards(:,1:ip)
if (ntde .gt. 0) then 
  ft(:,1:ntde)=cards(:,(2*ip+3+ntde+1):(2*ip+3+ntde*2))
  ftmap(:)=ioarray(4,ip+1:ip+ntde)
else
 ft=0
 ftmap=0
end if


bresx=x
ibresc=ic

do i=n-1,1,-1
 if (ic(i+1)-1 .gt. -0.0001) then
  if (dabs(t2(i)-t2(i+1)) .lt. 0.0001) then
   score_weights(i,:)=score_weights(i+1,:)
   bresx(i,:)=bresx(i,:)+bresx(i+1,:)
   ibresc(i)=ibresc(i)+ibresc(i+1)
   ibresc(i+1)=0
  end if
 end if
end do


score_weights=cards(:,(ip+4):(2*ip+3+ntde))



!   do i=1,n,1
!    t(i)=cards(i,ip+1)
!    ic(i)=cards(i,ip+2)
!    do j=1,ip,1
!     x(i,j)=cards(i,j)
!    end do
!   end do



!   XL ... log likelihood
!   FD ... First Derivative of log likelihood (=score vector)
!   SD ... Second Derivative of log likelihood
!   VM ... Variance Matrix ( = -SD**(-1) )
!   DINFO .Fisher Information (= -SD )
!   DINFOI.Inverse Fisher Information ( = VM )
!   SDI ...Inverse seconde derivative 

!   BX  ...Xb (n x 1)
!   EBX ...exp(Xb) (n x 1)
!   XEBX ..X'exp(Xb) (IP x 1)
!   XXEBX .sum(i)sum(j)sum(k)(X(i,k)*X(i,j)*exp(X(i,)*b))

!   XE  ...Unit vector
!     CI  ...confidence interval

    
!   Assuming that B maximizes the penalized likelihood

!write(6,*) "vor 1. LIKE"
CALL LIKE(N,IP,X,T1,t2,IC,XL,FD,SD,B,JCODE,IFIRTH,ngv,score_weights,bresx,ibresc, ntde,ft,ftmap) 
!write(6,*) "nach 1. Like"
wk(:,:)=-sd(:,:)
EPS=.000000000001D0
CALL INVERT(WK,IP+ntde,IP+ntde,VM,IP+ntde,EPS,IFAIL)                             
XLMAX=XL
IFAIL=0
!CONFLEV=1.-ALPHA
DCRILI=CRILI
DF=1.
!CHI=G01FCF(CONFLEV,DF,IFAIL)
XL0=XLMAX-0.5*CHI

bsave(:)=b(:)
xgrad(:)=fd(:)
xvm(:,:)=vm(:,:)
xhess(:,:)=sd(:,:)


!   DO 100 K=1,IP
do k=1,ip+ntde
!DO 101 L=1,2
 do L=1,2

!   L=1 ... lower limit
!   L=2 ... upper limit

  xe(:)=0

  XE(K)=1

  XSIGN=L*2-3
  XLAMBDA=0
!   Initialization of Likelihood, first and second der., beta
  vm(:,:)=xvm(:,:)
  sd(:,:)=xhess(:,:)
  fd(:)=xgrad(:)
  b(:)=bsave(:)

    
  ICONV=0
  ITER=0

!   DO 140 WHILE (ICONV .EQ. 0)
  DO WHILE (ICONV .EQ. 0)
   ITER=ITER+1  
   DO K2=1,IP+ntde
    DELTA(K2)=0

    DO K3=1,IP+ntde
     DELTA(K2)=DELTA(K2)+(FD(K3)+XLAMBDA*XE(K3))*VM(K2,K3)
    end do
    IF (DABS(DELTA(K2)) .GT. step) THEN
     DELTA(K2)=DSIGN(step,DELTA(K2))
    ENDIF
    B(K2)=B(K2)+DELTA(K2)
   end do

   CALL LIKE(N,IP,X,T1,t2,IC,XL,FD,SD,B,JCODE,IFIRTH,ngv,score_weights,bresx,ibresc,ntde,ft,ftmap) 
   wk(:,:)=-sd(:,:)
   EPS=.000000000001D0
   CALL INVERT(WK,IP+ntde,IP+ntde,VM,IP+ntde,EPS,IFAIL)                             


   GVG=0
   DO K2=1,IP+ntde
    DO K3=1,IP+ntde
     GVG=GVG+FD(K2)*FD(K3)*VM(K2,K3)
    end do
   end do

   XLAMBDA=XSIGN*(DSQRT(-(2*(XL0-XL-0.5*GVG)/VM(K,K))))


   AXLDIFF=DABS(XL0-XL) 
   IF (AXLDIFF <= DCRILI) THEN 
    ICONV=1
   ENDIF

   C2=0

   DO K2=1,IP+ntde
    DO K3=1,IP+ntde
     C2=C2+(FD(K2)+XLAMBDA*XE(K2))*(VM(K2,K3))*(FD(K3)+XLAMBDA*XE(K3))
    end do
   end do
    
   IF (C2 .GT. DCRILI) THEN 
    ICONV=0
   ENDIF

   IF (ITER .EQ. IMAXIT) THEN 
    ICONV=1
   ENDIF

  end do

  CI(K,L)=B(K)

  IOARRAY(6+L,K)=ITER
    
 end do
end do      

!   penalized LR p-values for H0:b(k)=0
    
!write (6,*) "vor p-value berechnung"

DO K2=1,IP+ntde
 OSSAVE=OFFSET(K2)
 IFLSAVE=IFLAG(K2)
 OFFSET(K2)=0
 IFLAG(K2)=0
 ITER=0
!   CALL FIRTHCOX(N,IP,X,T,IC,B,B0,XL,FD,SD,VM,BX,           
!     +JCODE,IFIRTH,CRILI,ISEP,ITER,IMAXIT,IMAXHS,STEP,IFLAG,
!     +OFFSET)

 parmsfc(1)=n
 parmsfc(2)=ip
 parmsfc(3)=ifirth
 parmsfc(4)=imaxit
 parmsfc(5)=imaxhs
 parmsfc(6)=step
 parmsfc(7)=crili
 parmsfc(8)=0
 parmsfc(9)=0
 parmsfc(10)=0
 parmsfc(11)=0
 parmsfc(12)=0
 parmsfc(13)=ngv
 parmsfc(14)=ntde
    
 do jjj=1,IP+ntde,1
  IOAFC(1,jjj)=1
 end do
!   IFLAG for estimation set to 0
 IOAFC(1,K2)=0
!   offset value 0
 IOAFC(2,K2)=0
 if (ntde .gt. 0) then
  do jjj=1, ntde
   ioafc(4,ip+jjj)=ftmap(jjj)
  end do
 end if
 CALL FIRTHCOX(CARDS, PARMSFC, IOAFC)
 IF (PARMSFC(8).GE.1) PARMS(9)=2
! write(6,*) "Var: " , k2
! write(6,*) "Code: ", parmsfc
! write(6,*) "likelihood: ", xl, xlmax
 xl=parmsfc(11)
 CHI=2*(XLMAX-XL)       
 IFAIL=0
 DF=1
! PV=G01ECF('U',CHI,DF,IFAIL)
 PVALUE(K2)=CHI
 OFFSET(K2)=OSSAVE
 IFLAG(K2)=IFLSAVE
end do



vm(:,:)=xvm(:,:)
sd(:,:)=xhess(:,:)
fd(:)=xgrad(:)
b(:)=bsave(:)
    
do j=1,ip+ntde
 do l=1,2
  ioarray(3+l,j)=ci(j,l)
 end do
 ioarray(6,j)=pvalue(j)
end do
    
!   JCODES (PARMS(9)): 2=problem in FIRTHCOX-CALL


!close(unit=6)

RETURN
END   


!      ________________________________________________________

! Code converted using TO_F90 by Alan Miller
! Date: 2006-04-13  Time: 10:09:09

!     |                                                        |
!     |  COMPUTE THE DETERMINANT OF A GENERAL FACTORED MATRIX  |
!     |                                                        |
!     |    INPUT:                                              |
!     |                                                        |
!     |         A     -FACT'S OUTPUT                           |
!     |                                                        |
!     |    OUTPUT:                                             |
!     |                                                        |
!     |         DET,E --DETERMINANT IS DET*10.**E (E INTEGER)  |
!     |                                                        |
!     |    BUILTIN FUNCTIONS: ABS,ALOG10,DLOG10                |
!     |________________________________________________________|

FUNCTION det(e,a,nin)

INTEGER, INTENT(OUT)            :: e
integer, intent(in)             :: nin
REAL*8, INTENT(IN)              :: a(3+nin*(nin+1))
REAL*8 :: d,f,g
DOUBLE PRECISION :: c
INTEGER :: h,i,j,k,l,m,n

intrinsic DABS, dlog10

d = a(1)
IF ( DABS(d) == 1230 ) GO TO 10
!WRITE(6,*) 'ERROR: MUST FACTOR BEFORE COMPUTING DETERMINANT'
!STOP
10    e = 0
IF ( d < 0. ) GO TO 70
n = a(2)
IF ( n == 1 ) GO TO 80
d = 1.
f = 2.**64
g = 1./f
h = 64
m = n + 1
j = 0
k = 4
l = 3 - m + m*n
DO  i = k,l,m
  j = j + 1
  IF ( a(i) > j ) d = -d
  d = d*a(i+j)
  20         IF ( DABS(d) < f ) GO TO 30
  e = e + h
  d = d*g
  GO TO 20
  30         IF ( DABS(d) > g ) CYCLE
  e = e - h
  d = d*f
  GO TO 30
END DO
d = d*a(l+m)
IF ( e /= 0 ) GO TO 50
det = d
RETURN
50    IF ( d == 0. ) GO TO 90
c = DLOG10(DABS(d)) + e*DLOG10(2.d0)
e = c
c = c - e
IF ( c <= 0.d0 ) GO TO 60
c = c - 1
e = e + 1
60    f = 10.**c
IF ( d < 0. ) f = -f
det = f
RETURN
70    det = 0.
RETURN
80    det = a(5)
RETURN
90    e = 0
GO TO 70
END FUNCTION det

!

! Code converted using TO_F90 by Alan Miller
! Date: 2006-04-13  Time: 10:10:03

!      ________________________________________________________
!     |                                                        |
!     |     FACTOR A GENERAL MATRIX WITH PARTIAL PIVOTING      |
!     |                                                        |
!     |    INPUT:                                              |
!     |                                                        |
!     |         A     --ARRAY CONTAINING MATRIX                |
!     |                 (LENGTH AT LEAST 3 + N(N+1))           |
!     |                                                        |
!     |         LA    --LEADING (ROW) DIMENSION OF ARRAY A     |
!     |                                                        |
!     |         N     --DIMENSION OF MATRIX STORED IN A        |
!     |                                                        |
!     |    OUTPUT:                                             |
!     |                                                        |
!     |         A     --FACTORED MATRIX                        |
!     |                                                        |
!     |    BUILTIN FUNCTIONS: ABS                              |
!     |    PACKAGE SUBROUTINES: PACK                           |
!     |________________________________________________________|

SUBROUTINE fact(ain,a,la,n)

INTEGER, INTENT(IN)                      :: la
INTEGER, INTENT(IN)                      :: n
REAL*8, INTENT(in OUT)                     :: a(3+n*(n+1))
real*8, intent(in)              ::  ain(n,n)
REAL*8 :: r,s,t
INTEGER :: e,f,g,h,i,j,k,l, m, o,p

intrinsic dabs

!IF ( la > n ) CALL pack(a,la,n)
!nicht notwendig da la immer = N

do i=1,n
 do j=1,n
  a((i-1)*n+j)=ain(i,j)
 end do
end do


r = 0.
o = n + 1
p = o + 1
l = 5 + n*p
i = -n - 3
!     ---------------------------------------------
!     |*** INSERT PIVOT ROW AND COMPUTE 1-NORM ***|
!     ---------------------------------------------
10    l = l - o
IF ( l == 4 ) GO TO 30
s = 0.
DO  k = 1,n
  j = l - k
  t = a(i+j)
  a(j) = t
  s = s + DABS(t)
END DO
IF ( r < s ) r = s
i = i + 1
GO TO 10
30    a(1) = 1230
a(2) = n
a(3) = r
i = 5 - p
k = 1
40    i = i + p
IF ( k == n ) GO TO 110
e = n - k
m = i + 1
h = i
l = i + e
!     ---------------------------------------
!     |*** FIND PIVOT AND START ROW SWAP ***|
!     ---------------------------------------
DO  j = m,l
  IF ( DABS(a(j)) > DABS(a(h)) ) h = j
END DO
g = h - i
j = i - k
a(j) = g + k
t = a(h)
a(h) = a(i)
a(i) = t
k = k + 1
IF ( t == 0. ) GO TO 100
!     -----------------------------
!     |*** COMPUTE MULTIPLIERS ***|
!     -----------------------------
DO  j = m,l
  a(j) = a(j)/t
END DO
f = i + e*o
70    j = k + l
h = j + g
t = a(h)
a(h) = a(j)
a(j) = t
l = e + j
IF ( t == 0. ) GO TO 90
h = i - j
!     ------------------------------
!     |*** ELIMINATE BY COLUMNS ***|
!     ------------------------------
m = j + 1
DO  j = m,l
  a(j) = a(j) - t*a(j+h)
END DO
90    IF ( l < f ) GO TO 70
GO TO 40
100   a(1) = -1230
GO TO 40
110   IF ( a(i) == 0. ) a(1) = -1230
RETURN
END SUBROUTINE fact


!

! Code converted using TO_F90 by Alan Miller
! Date: 2006-04-13  Time: 10:10:05

!      ________________________________________________________
!     |                                                        |
!     |   REARRANGE THE ELEMENTS OF A REAL ARRAY SO THAT THE   |
!     |  ELEMENTS OF A SQUARE MATRIX ARE STORED SEQUENTIALLY   |
!     |                                                        |
!     |    INPUT:                                              |
!     |                                                        |
!     |         A     --REAL ARRAY CONTAINING SQUARE MATRIX    |
!     |                                                        |
!     |         LA    --LEADING (ROW) DIMENSION OF ARRAY A     |
!     |                                                        |
!     |         N     --DIMENSION OF MATRIX STORED IN A        |
!     |                                                        |
!     |    OUTPUT:                                             |
!     |                                                        |
!     |         A     --MATRIX PACKED AT START OF ARRAY        |
!     |________________________________________________________|

SUBROUTINE packna(a,la,n)

REAL*8, INTENT(OUT)                        :: a(1)
INTEGER, INTENT(IN)                      :: la
INTEGER, INTENT(IN)                      :: n

INTEGER :: h,i,j,k,l, o

h = la - n
IF ( h == 0 ) RETURN
IF ( h > 0 ) GO TO 10
! WRITE(6,*) 'ERROR: LA ARGUMENT IN PACK MUST BE .GE. N ARGUMENT'
STOP
10    i = 0
k = 1
l = n
o = n*n
20    IF ( l == o ) RETURN
i = i + h
k = k + n
l = l + n
DO  j = k,l
  a(j) = a(i+j)
END DO
GO TO 20
END SUBROUTINE packna


!

! Code converted using TO_F90 by Alan Miller
! Date: 2006-04-13  Time: 10:09:46

!      ________________________________________________________
!     |                                                        |
!     |                INVERT A GENERAL MATRIX                 |
!     |                                                        |
!     |    INPUT:                                              |
!     |                                                        |
!     |         V     --ARRAY CONTAINING MATRIX                |
!     |                                                        |
!     |         LV    --LEADING (ROW) DIMENSION OF ARRAY V     |
!     |                                                        |
!     |         N     --DIMENSION OF MATRIX STORED IN ARRAY V  |
!     |                                                        |
!     |         W     --INTEGER WORK ARRAY WITH AT LEAST N-1   |
!     |                      ELEMENTS                          |
!     |                                                        |
!     |    OUTPUT:                                             |
!     |                                                        |
!     |         V     --INVERSE                                |
!     |                                                        |
!     |    BUILTIN FUNCTIONS: ABS                              |
!     |________________________________________________________|

SUBROUTINE vert(v,lv,n,w)

INTEGER, INTENT(IN OUT)                  :: lv
INTEGER, INTENT(IN)                      :: n
REAL*8, INTENT(IN OUT)                     :: v(lv,N)
REAL*8, INTENT(OUT)                     :: w(N)
REAL*8 :: s,t
INTEGER :: i,j,k,l,m, p

!Anm GH bei den Dimensionen die Indizes ver�ndert, waren v(lv,1) und w(1) vorher

intrinsic dabs

IF ( n == 1 ) GO TO 110
l = 0
m = 1
10    IF ( l == n ) GO TO 90
k = l
l = m
m = m + 1
!     ---------------------------------------
!     |*** FIND PIVOT AND START ROW SWAP ***|
!     ---------------------------------------
p = l
IF ( m > n ) GO TO 30
s = DABS(v(l,l))
DO  i = m,n
  t = DABS(v(i,l))
  IF ( t <= s ) CYCLE
  p = i
  s = t
END DO
w(l) = p
30    s = v(p,l)
v(p,l) = v(l,l)
IF ( s == 0. ) GO TO 120
!     -----------------------------
!     |*** COMPUTE MULTIPLIERS ***|
!     -----------------------------
v(l,l) = -1.
s = 1./s
DO  i = 1,n
  v(i,l) = -s*v(i,l)
END DO
j = l
50    j = j + 1
IF ( j > n ) j = 1
IF ( j == l ) GO TO 10
t = v(p,j)
v(p,j) = v(l,j)
v(l,j) = t
IF ( t == 0. ) GO TO 50
!     ------------------------------
!     |*** ELIMINATE BY COLUMNS ***|
!     ------------------------------
IF ( k == 0 ) GO TO 70
DO  i = 1,k
  v(i,j) = v(i,j) + t*v(i,l)
END DO
70    v(l,j) = s*t
IF ( m > n ) GO TO 50
DO  i = m,n
  v(i,j) = v(i,j) + t*v(i,l)
END DO
GO TO 50
!     -----------------------
!     |*** PIVOT COLUMNS ***|
!     -----------------------
90    l = w(k)
DO  i = 1,n
  t = v(i,l)
  v(i,l) = v(i,k)
  v(i,k) = t
END DO
k = k - 1
IF ( k > 0 ) GO TO 90
RETURN
110   IF ( v(1,1) == 0. ) GO TO 120
v(1,1) = 1./v(1,1)
RETURN
120   continue
!WRITE(6,*) 'ERROR: MATRIX HAS NO INVERSE'
STOP
END SUBROUTINE vert
