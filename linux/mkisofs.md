# mkisofs


```shell
sudo md5sum `find ! -name “md5sum.txt” ! -path “./isolinux/*” -follow -type f` > md5sum.txt
sudo mkisofs -J -l -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -z -iso-level 4 -c isolinux/isolinux.cat -o ./qdss-2.8.0.iso -joliet-long qdss-2.8.0/
```

